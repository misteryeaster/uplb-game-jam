extends Camera3D

@export var initial_pos: Vector3

@onready var game_started: bool = false

func _physics_process(delta: float) -> void:
	if (!game_started):
		return
		
	global_position += Vector3.FORWARD * 10 * delta

func _on_game_game_started() -> void:
	game_started = true

func _on_player_just_reset() -> void:
	global_position = initial_pos
	
	game_started = false
