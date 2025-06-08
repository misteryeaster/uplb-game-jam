extends CharacterBody3D

signal died
signal just_reset
signal cooled
signal health_changed
signal health_percentage_changed
signal picked_up

@export_category("movement")
# Rename this to clearly indicate it's the base speed
@export var base_movement_speed: float
@export var jump_height: float
@export var rise_time: float
@export var fall_time: float

@export_category("gameplay")
@export var lane_spacing: float = 3

@export_category("effects")
@export var effect_limit: int = 3

# --- NEW: Heat Integration ---
@export_category("Heat Interaction")
@export var heat_bar_node: Node
# The minimum speed factor when heat is at maximum (e.g., 0.5 means half speed)
@export var min_speed_factor_at_max_heat: float = 0.5

# --- NEW: Footsteps Audio Settings ---
@export_category("Footsteps Audio")
# The base pitch of footsteps at normal speed
@export var base_footsteps_pitch: float = 1.0
# Minimum pitch when speed is at its lowest
@export var min_footsteps_pitch: float = 0.5
# Maximum pitch when speed is at its highest
@export var max_footsteps_pitch: float = 2.0

var base_effect_timer: PackedScene = preload("res://gameplay/player/effect_timer.tscn")

@onready var jump_velocity: float = 2 * jump_height / rise_time
@onready var rise_gravity: float = 2 * jump_height / (rise_time * rise_time)
@onready var fall_gravity: float = 2 * jump_height / (fall_time * fall_time)
@onready var initial_position: Vector3 = global_position

@onready var current_lane: int = 0:
	set(value):
		current_lane = clamp(value, -1, 1)

# Removed the setter, we'll manage speed multipliers directly
@onready var current_move_speed: float = base_movement_speed:
	set(value):
		current_move_speed = max(value, base_movement_speed)

@onready var game_started: bool = false
@onready var applied_effects: Array[String] = []

# --- NEW: Speed Multipliers ---
# Multiplier from effects like "energy" (defaults to 1.0)
var _effect_speed_multiplier: float = 1.0
# Multiplier calculated from heat (defaults to 1.0)
var _heat_speed_multiplier: float = 1.0

func _ready():
	current_lane = 0
	global_position = initial_position
	$Footsteps.stop()
	
	if heat_bar_node:
		heat_bar_node.heat_changed.connect(_on_heat_bar_heat_changed_by_player)
		print("Player connected to HeatBar heat_changed signal.")
		
		if heat_bar_node.max_heat > 0:
			_on_heat_bar_heat_changed_by_player(heat_bar_node.heat)
		else:
			printerr("Warning: HeatBar max_heat is 0 or less, cannot calculate initial heat penalty.")
	else:
		printerr("Warning: Player heat_bar_node not assigned in Inspector!")

func _physics_process(delta: float) -> void:
	if (!game_started):
		return

	# Calculate the effective speed rate based on base speed and multipliers
	var current_speed_rate = base_movement_speed * _effect_speed_multiplier * _heat_speed_multiplier

	# Apply the speed rate to the Z velocity (negative because moving forward on -Z)
	velocity.z = -current_speed_rate * delta

	# Update footsteps tempo based on current speed
	_update_footsteps_tempo()

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

	global_position.x = lerp(global_position.x, current_lane * lane_spacing, 10 * delta)
	move_and_slide()

# --- NEW: Function to update footsteps tempo ---
func _update_footsteps_tempo():
	if !$Footsteps:
		return
		
	# Calculate the total speed multiplier
	var total_speed_multiplier = _effect_speed_multiplier * _heat_speed_multiplier
	
	# Calculate the pitch based on speed multiplier
	# This maps the speed multiplier to a pitch range
	var target_pitch: float
	
	if total_speed_multiplier >= 1.0:
		# Speed is normal or faster - interpolate between base and max pitch
		var speed_factor = min(total_speed_multiplier, 2.0) # Cap at 2x for pitch calculation
		target_pitch = lerp(base_footsteps_pitch, max_footsteps_pitch, (speed_factor - 1.0))
	else:
		# Speed is slower than normal - interpolate between min and base pitch
		target_pitch = lerp(min_footsteps_pitch, base_footsteps_pitch, total_speed_multiplier)
	
	# Apply the pitch to the footsteps audio
	$Footsteps.pitch_scale = target_pitch

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
	# Set initial footsteps tempo
	_update_footsteps_tempo()

func _on_health_depleted() -> void:
	on_death()

func create_effect(effect_id: String, duration: float):
	var new_effect_timer: Timer = base_effect_timer.instantiate()
	new_effect_timer.id = effect_id
	new_effect_timer.duration = duration
	new_effect_timer.connect("expired", on_effect_expiry)
	
	# Only add if not already present to avoid stacking multiple timers for the same effect type
	if !applied_effects.has(effect_id):
		applied_effects.append(effect_id)
	
	$Effects.add_child(new_effect_timer)

func on_effect_expiry(effect_id: String):
	# Remove from the list of applied effects
	if applied_effects.has(effect_id):
		applied_effects.erase(effect_id)
	
	match effect_id:
		"energy":
			_effect_speed_multiplier = 1.0 # Reset the multiplier

func pickup_water():
	cooled.emit(50)

func pickup_energy():
	# Check for existing energy effect timers
	var existing_energy_timers: Array[Timer] = []
	for child in $Effects.get_children():
		if child is Timer and child.id == "energy":
			existing_energy_timers.append(child)
	
	# If we already have energy effects active, reset their duration instead of creating new ones
	if existing_energy_timers.size() > 0:
		print("Resetting energy effect duration.")
		for timer in existing_energy_timers:
			timer.wait_time = 5.0  # Reset to full duration
			timer.start()  # Restart the timer
		return
	
	# Check if we've hit the effect limit (only matters for new effects)
	if (existing_energy_timers.size() >= effect_limit):
		print("Energy effect limit reached.")
		return
		
	# Apply the effect multiplier
	_effect_speed_multiplier = 2.0
	
	# Create a timer for this effect
	create_effect("energy", 5)

func pickup(pickup_id: String):
	picked_up.emit(pickup_id)
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

# --- NEW: Signal handler for HeatBar's heat_changed signal ---
func _on_heat_bar_heat_changed_by_player(new_heat_value: float) -> void:
	if !heat_bar_node or heat_bar_node.max_heat <= 0:
		_heat_speed_multiplier = 1.0 # Default to no penalty if HeatBar is invalid
		return

	# Calculate the heat percentage (0 to 1)
	var heat_percentage = clamp(new_heat_value / heat_bar_node.max_heat, 0.0, 1.0)

	# Calculate the speed multiplier using linear interpolation (lerp)
	# At 0% heat, multiplier is 1.0 (full speed)
	# At 100% heat, multiplier is min_speed_factor_at_max_heat
	_heat_speed_multiplier = lerp(1.0, min_speed_factor_at_max_heat, heat_percentage)
