extends Camera3D

@export var x_smoothing: float = 15.0  # Increased for faster lane switching
@export var shake_intensity: float = 0.3

@onready var game_started: bool = false
@onready var player: Node3D
@onready var offset: Vector3
@onready var shake_timer: float = 0.0
@onready var base_position: Vector3

@onready var initial_pos: Vector3 = global_position

@onready var finished: bool = false

func _ready():
	player = get_node("../Player")
	if player:
		offset = global_position - player.global_position
	base_position = global_position

func _physics_process(delta: float) -> void:
	if !game_started or !player:
		return
	
	# Calculate base target position
	if (!finished):
		var target_pos = player.global_position + offset
	
		# Update base position - NO smoothing for Z (forward movement)
		base_position.z = target_pos.z  # Move instantly with player forward movement
		base_position.x = lerp(base_position.x, target_pos.x, x_smoothing * delta)  # Fast smoothing for lane switching
		base_position.y = target_pos.y  # Keep Y from offset
	
	# Apply shake as offset from base position
	var shake_offset = Vector3.ZERO
	if shake_timer > 0:
		shake_timer -= delta
		var shake_amount = shake_timer * shake_intensity
		shake_offset = Vector3(
			randf_range(-shake_amount, shake_amount),
			randf_range(-shake_amount, shake_amount),
			0
		)
	
	# Set final position
	global_position = base_position + shake_offset

func _on_game_game_started() -> void:
	game_started = true
	finished = false
	
	if player:
		offset = initial_pos - player.global_position

func _on_player_just_reset() -> void:
	base_position = initial_pos
	global_position = initial_pos

	shake_timer = 0.0
	
	# Recalculate offset when player resets
	if player:
		offset = initial_pos - player.global_position

func _on_hurtbox_hurt(damage) -> void:
	shake_timer = 0.5 + (damage * 0.1)

func _on_player_player_won() -> void:
	finished = true
