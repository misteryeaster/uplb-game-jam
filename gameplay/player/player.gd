extends Node3D

signal died
signal just_reset
signal lane_changed

@export var initial_position: Vector3
@export var lane_spacing: float = 3

@onready var current_lane: int = 0:
	set(value):
		var old_lane = current_lane
		current_lane = clamp(value, -1, 1)
		if old_lane != current_lane:
			lane_changed.emit()
		
@onready var game_started: bool = false
@onready var sprite: Sprite3D
@onready var is_stunned: bool = false

var knockback_force: Vector3 = Vector3.ZERO
var stun_timer: float = 0.0

func _ready():
	sprite = $Sprite3D

func _physics_process(delta: float) -> void:
	if !game_started:
		return
	
	# Handle stun timer
	if stun_timer > 0:
		stun_timer -= delta
		is_stunned = stun_timer > 0
	
	# Apply knockback (gradually reduce)
	if knockback_force.length() > 0.1:
		global_position += knockback_force * delta
		knockback_force = knockback_force.lerp(Vector3.ZERO, 8.0 * delta)
	else:
		knockback_force = Vector3.ZERO
	
	# Normal forward movement (reduced if stunned)
	var move_speed = 10.0 if !is_stunned else 5.0
	global_position += Vector3.FORWARD * move_speed * delta
	
	# Lane movement (disabled if stunned)
	global_position.x = lerp(global_position.x, current_lane * lane_spacing, 10 * delta)
	
	# Input (only if not stunned)
	if !is_stunned:
		if Input.is_action_just_pressed("move_left"):
			current_lane -= 1
			
		if Input.is_action_just_pressed("move_right"):
			current_lane += 1

func take_damage(damage: float, hit_position: Vector3 = Vector3.ZERO):
	# Calculate knockback direction
	var knockback_direction = Vector3.BACK * 2.0  # Push player backward
	
	# Add some randomness to knockback
	knockback_direction.x += randf_range(-1.0, 1.0)
	knockback_direction.y = 0.5  # Small upward bump
	
	# Apply knockback force
	knockback_force = knockback_direction * damage
	
	# Stun player briefly
	stun_timer = 0.3 + (damage * 0.1)
	is_stunned = true
	
	# Visual feedback
	add_hurt_effect(damage)

func add_hurt_effect(damage: float):
	if !sprite:
		return
	
	var tween = create_tween()
	tween.set_parallel(true)
	
	# Color flash (red)
	tween.tween_property(sprite, "modulate", Color.RED, 0.1)
	tween.tween_property(sprite, "modulate", Color.WHITE, 0.2).set_delay(0.1)
	
	# Scale effect (bigger damage = bigger effect)
	var scale_amount = 1.0 + (damage * 0.1)
	tween.tween_property(sprite, "scale", Vector3(scale_amount, 0.3, 0.5), 0.1)
	tween.tween_property(sprite, "scale", Vector3(0.5, 0.5, 0.5), 0.3).set_delay(0.1)
	
	# Rotation wobble
	var wobble_amount = damage * 10.0
	tween.tween_property(sprite, "rotation_degrees:z", wobble_amount, 0.05)
	tween.tween_property(sprite, "rotation_degrees:z", -wobble_amount * 0.5, 0.1).set_delay(0.05)
	tween.tween_property(sprite, "rotation_degrees:z", 0, 0.15).set_delay(0.15)

func reset():
	current_lane = 0
	global_position = initial_position
	knockback_force = Vector3.ZERO
	stun_timer = 0.0
	is_stunned = false
	
	if sprite:
		sprite.modulate = Color.WHITE
		sprite.scale = Vector3(0.5, 0.5, 0.5)
		sprite.rotation_degrees = Vector3.ZERO
	
	just_reset.emit()
	
func on_death():
	game_started = false
	died.emit()
	reset()
		
func _on_game_game_started() -> void:
	game_started = true

func _on_health_depleted() -> void:
	on_death()

# Connect this to your hurtbox hurt signal
func _on_hurtbox_hurt(damage: float) -> void:
	take_damage(damage)
