extends CharacterBody3D

signal died
signal just_reset

signal cooled

signal health_changed
signal health_percentage_changed

signal picked_up

@export_category("movement")

@export var movement_speed: float

@export var jump_height: float
@export var rise_time: float
@export var fall_time: float

@export_category("gameplay")

@export var lane_spacing: float = 3

@export_category("effects")

@export var effect_limit: int = 3

var base_effect_timer: PackedScene = preload("res://gameplay/player/effect_timer.tscn")

@onready var jump_velocity: float = 2 * jump_height / rise_time

@onready var rise_gravity: float = 2 * jump_height / (rise_time * rise_time)
@onready var fall_gravity: float = 2 * jump_height / (fall_time * fall_time)

@onready var initial_position: Vector3 = global_position

@onready var current_lane: int = 0:
	set(value):
		current_lane = clamp(value, -1, 1)
		
@onready var current_move_speed: float = movement_speed:
	set(value):
		current_move_speed = max(value, movement_speed)
		
@onready var game_started: bool = false

@onready var applied_effects: Array[String] = []

func _ready():
	# Add player to group so particles can find it easily
	add_to_group("player")
	
	current_lane = 0
	global_position = initial_position
	$Footsteps.stop()

func _physics_process(delta: float) -> void:
	if (!game_started):
		return
		
	velocity.z = -current_move_speed * delta
	
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
	
	#if (Input.is_action_just_pressed("move_jump")):
		#velocity.y = jump_velocity
		
	global_position.x = lerp(global_position.x, current_lane * lane_spacing, 10 * delta)
	
	move_and_slide()

func reset():
	current_lane = 0
	
	global_position = initial_position
	
	just_reset.emit()
	
func on_death():
	game_started = false
	
	$Footsteps.stop()
	
	died.emit()
	
	reset()
		
func _on_game_game_started() -> void:
	$Footsteps.play()
	
	game_started = true

func _on_health_depleted() -> void:
	on_death()
	
func create_effect(effect_id: String, duration: float):
	#print("Created effect " + effect_id + ".")
	#
	var new_effect_timer: Timer = base_effect_timer.instantiate()
	
	new_effect_timer.id = effect_id
	new_effect_timer.duration = 5
	
	new_effect_timer.connect("expired", on_effect_expiry)
	
	applied_effects.append(effect_id)
	
	$Effects.add_child(new_effect_timer)
	
func on_effect_expiry(effect_id: String):
	if (!applied_effects.has(effect_id)):
		printerr("Effect was not recognized as applied yet it expired?")
		return
		
	applied_effects.erase(effect_id)
	
	var alone: bool = applied_effects.has(effect_id)
	
	match effect_id:
		"energy":
			current_move_speed /= 1.5
	
func pickup_water():
	cooled.emit(50)
	
func pickup_energy():
	var existing: int = applied_effects.count("energy")
	
	create_effect("energy", 1)
	
	if (existing > effect_limit):
		return
		
	current_move_speed *= 1.5

func pickup(pickup_id: String):
	picked_up.emit(pickup_id)
	print("Picked up " + pickup_id + ".")
	match pickup_id:
		"water":
			pickup_water()
			
		"energy":
			pickup_energy()
	
func _on_pickup_area_picked_up(pickup_id: String) -> void:
	pickup(pickup_id)


func _on_health_health_changed(health: float) -> void:
	health_changed.emit(health)

func _on_health_health_percentage_changed(health_percentage: float) -> void:
	health_percentage_changed.emit(health_percentage)
