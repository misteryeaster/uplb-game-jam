extends CharacterBody3D

signal died
signal just_reset

@export_category("movement")

@export var movement_speed: float

@export var jump_height: float
@export var rise_time: float
@export var fall_time: float

@export_category("gameplay")
@export var initial_position: Vector3
@export var lane_spacing: float = 3

@onready var jump_velocity: float = 2 * jump_height / rise_time

@onready var rise_gravity: float = 2 * jump_height / (rise_time * rise_time)
@onready var fall_gravity: float = 2 * jump_height / (fall_time * fall_time)

@onready var current_lane: int = 0:
	set(value):
		current_lane = clamp(value, -1, 1)
		
@onready var game_started: bool = false

func _physics_process(delta: float) -> void:
	if (!game_started):
		return
		
	velocity.z = -movement_speed * delta
	
	if (!is_on_floor()):
		if (Input.is_action_pressed("move_jump")):
			velocity.y -= rise_gravity * delta
			
		else:
			velocity.y -= fall_gravity * delta
		
	else:
		velocity.y = 0
	
	if (Input.is_action_just_pressed("move_left")):
		current_lane -= 1
		
	if (Input.is_action_just_pressed("move_right")):
		current_lane += 1
	
	if (Input.is_action_just_pressed("move_jump")):
		velocity.y = jump_velocity
		
	global_position.x = lerp(global_position.x, current_lane * lane_spacing, 10 * delta)
		
	move_and_slide()

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
