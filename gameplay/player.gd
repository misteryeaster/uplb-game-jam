extends Node3D

signal died
signal just_reset

@export var initial_position: Vector3

@export var lane_spacing: float = 3

@onready var current_lane: int = 0:
	set(value):
		current_lane = clamp(value, -1, 1)
		
@onready var game_started: bool = false

func _physics_process(delta: float) -> void:
	if (!game_started):
		return
		
	global_position += Vector3.FORWARD * 10 * delta
	
	global_position.x = lerp(global_position.x, current_lane * lane_spacing, 10 * delta)
	
	if (Input.is_action_just_pressed("move_left")):
		current_lane -= 1
		
	if (Input.is_action_just_pressed("move_right")):
		current_lane += 1

func reset():
	current_lane = 0
	
	global_position = initial_position
	
	just_reset.emit()
	
func on_death():
	game_started = false
	
	died.emit()
	
	reset()
	
func _ready():
	current_lane = 0
	
	global_position = initial_position
		
func _on_game_game_started() -> void:
	game_started = true

func _on_health_depleted() -> void:
	on_death()
