extends Node3D
signal game_started
signal game_ended
signal game_finished
signal time_up
signal time_warning
signal time_changed(remaining_time: float)

@export_category("Game Settings")
@export var level_time_limit: float = 120.0  # 2 minutes in seconds
@export var warning_time: float = 30.0  # Show warning when 30 seconds left

@export_category("UI References")
@export var time_label: Label  # Drag your Label node here in the inspector

@onready var game_ongoing: bool = false

# Timer state variables
var current_time: float = 0.0
var timer_active: bool = false
var warning_shown: bool = false

func _ready():
	# Initialize timer
	current_time = level_time_limit
	
	# Connect to our own time_changed signal to update the label
	time_changed.connect(_on_time_changed)
	
	# Connect to player signals (adjust the path to your player node)
	var player = get_node("/root/Main/World/Player")  # Adjust this path to your player
	if player:
		player.player_won.connect(_on_player_won)
	
	# Update label initially
	update_time_label()

func _process(delta):
	# Only process timer if game is ongoing and timer is active
	if not game_ongoing or not timer_active:
		return
	
	# Countdown the timer
	current_time -= delta
	time_changed.emit(current_time)  # Emit for UI updates
	
	# Check for warning
	if not warning_shown and current_time <= warning_time:
		warning_shown = true
		time_warning.emit()
		print("WARNING: Only ", warning_time, " seconds left!")
	
	# Check if time is up
	if current_time <= 0:
		_on_time_up()

# Update the time label display
func update_time_label():
	if not time_label:
		return
	
	var minutes = int(current_time) / 60
	var seconds = int(current_time) % 60
	time_label.text = "%02d:%02d" % [minutes, seconds]

# Signal handler for time changes
func _on_time_changed(remaining_time: float):
	update_time_label()

func is_game_ongoing() -> bool:
	return game_ongoing

func start_timer():
	timer_active = true
	print("Timer started! ", level_time_limit, " seconds to complete the level.")

func stop_timer():
	timer_active = false

func reset_timer():
	current_time = level_time_limit
	timer_active = false
	warning_shown = false
	update_time_label()  # Update label when resetting

func get_remaining_time() -> float:
	return current_time

func get_time_percentage() -> float:
	return current_time / level_time_limit if level_time_limit > 0 else 0.0

func _on_time_up():
	print("TIME'S UP! Game Over!")
	time_up.emit()
	end()  # End the game when time runs out

func exit():
	print("Game exited.")
	get_tree().quit()

func start() -> void:
	print("=== START() CALLED ===")
	print("Current game_ongoing state: ", game_ongoing)
	print("Current timer_active state: ", timer_active)
	print("Current time: ", current_time)
	
	if (game_ongoing):
		printerr("Game is already ongoing?")
		return
	
	# Reset game state completely
	reset_game_state()
	
	# Reset and start timer
	reset_timer()
	start_timer()
	
	game_started.emit()
	game_ongoing = true
	
	print("Game started successfully!")
	print("New game_ongoing state: ", game_ongoing)
	print("New timer_active state: ", timer_active)
	print("New current_time: ", current_time)

func end() -> void:
	print("=== END() CALLED ===")
	print("Current game_ongoing state: ", game_ongoing)
	
	if (!game_ongoing):
		printerr("Game is not ongoing?")
		return
		
	# Stop timer
	stop_timer()
	
	game_ended.emit()
	game_ongoing = false
	
	print("Game ended successfully!")
	print("New game_ongoing state: ", game_ongoing)

# New function to reset all game state
func reset_game_state():
	print("=== RESETTING GAME STATE ===")
	
	# Reset timer state
	current_time = level_time_limit
	timer_active = false
	warning_shown = false
	
	# Reset player state (adjust path to your player)
	var player = get_node("/root/Main/World/Player")
	if player:
		print("Player found, attempting to reset...")
		if player.has_method("reset_player"):
			player.reset_player()
			print("Player reset method called")
		else:
			print("WARNING: Player doesn't have reset_player() method")
			# Manual reset of common player properties
			if "global_position" in player:
				# Try to find a spawn point or use a default position
				var spawn_point = get_node_or_null("/root/Main/World/SpawnPoint")
				if spawn_point:
					player.global_position = spawn_point.global_position
					print("Reset player to spawn point: ", spawn_point.global_position)
				else:
					# Fallback to a default starting position (adjust as needed)
					player.global_position = Vector3(0, 0, 0)  # or Vector2(0, 0) for 2D
					print("Reset player to default position (0,0,0)")
			
			if "has_won" in player:
				player.has_won = false
				print("Reset player has_won to false")
			
			# Reset other common player states
			if "velocity" in player:
				player.velocity = Vector3.ZERO  # or Vector2.ZERO for 2D
				print("Reset player velocity")
	else:
		print("WARNING: Player node not found!")
	
	# Reset level objects (collectibles, enemies, etc.)
	reset_level_objects()
	
# Reset level objects like collectibles, enemies, etc.
func reset_level_objects():
	print("Resetting level objects...")
	
	# Reset collectibles (adjust path as needed)
	var collectibles = get_tree().get_nodes_in_group("collectibles")
	for collectible in collectibles:
		if collectible.has_method("reset"):
			collectible.reset()
		elif "visible" in collectible:
			collectible.visible = true
		elif "show" in collectible:
			collectible.show()
	
	# Reset enemies (adjust path as needed)
	var enemies = get_tree().get_nodes_in_group("enemies")
	for enemy in enemies:
		if enemy.has_method("reset"):
			enemy.reset()
	
	# Reset goal/end trigger (make sure it can be triggered again)
	var goal = get_tree().get_first_node_in_group("goal")
	if goal and goal.has_method("reset"):
		goal.reset()
	
	print("Level objects reset completed.")

# Existing signal handlers
func _on_play_button_game_start_requested() -> void:
	start()

func _on_exit_button_game_exit_requested() -> void:
	exit()

func _on_player_died() -> void:
	end()

# Fixed signal handler for win condition
func _on_player_won() -> void:
	stop_timer()  # Stop the timer immediately when player wins
	
	$Timer.start()
	
# Optional: Add restart functionality
func restart() -> void:
	if game_ongoing:
		end()
	
	# Wait a frame to ensure end() is processed
	await get_tree().process_frame
	start()

func _on_player_player_won() -> void:
	$Timer.start()

func _on_timer_timeout() -> void:
	print("Game finished!")
	
	game_finished.emit(current_time)

func _on_play_button_game_restart_requested() -> void:
	restart()

func _on_quit_button_game_quit_requested() -> void:
	end()
