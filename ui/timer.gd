# TimeManager.gd
extends Node
class_name TimeManager

signal time_up
signal time_warning
signal time_changed(remaining_time: float)

@export_category("Timer Settings")
@export var level_time_limit: float = 120.0  # 2 minutes in seconds
@export var warning_time: float = 30.0  # Show warning when 30 seconds left

@export_category("UI References")
@export var time_label: Label  # Drag your Label node here in the inspector

# Timer state variables
var current_time: float = 0.0
var timer_active: bool = false
var warning_shown: bool = false

func _ready():
	# Initialize timer
	current_time = level_time_limit
	
	# Connect to our own time_changed signal to update the label
	time_changed.connect(_on_time_changed)
	
	# Update label initially
	_update_time_label()

func _process(delta):
	# Only process timer if timer is active
	if not timer_active:
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
func _update_time_label():
	if not time_label:
		return
	
	var minutes = int(current_time) / 60
	var seconds = int(current_time) % 60
	time_label.text = "%02d:%02d" % [minutes, seconds]

# Signal handler for time changes
func _on_time_changed(remaining_time: float):
	_update_time_label()

func start_timer():
	timer_active = true
	print("Timer started! ", level_time_limit, " seconds to complete the level.")

func stop_timer():
	timer_active = false
	print("Timer stopped.")

func pause_timer():
	timer_active = false

func resume_timer():
	timer_active = true

func reset_timer():
	current_time = level_time_limit
	timer_active = false
	warning_shown = false
	_update_time_label()  # Update label when resetting

func get_remaining_time() -> float:
	return current_time

func get_time_percentage() -> float:
	return current_time / level_time_limit if level_time_limit > 0 else 0.0

func is_timer_active() -> bool:
	return timer_active

func _on_time_up():
	print("TIME'S UP!")
	stop_timer()
	time_up.emit()

# Methods to be called by GameManager
func on_game_started():
	reset_timer()
	start_timer()

func on_game_ended():
	stop_timer()

func on_player_won():
	print("Timer stopped - Player won with ", current_time, " seconds remaining!")
	stop_timer()
