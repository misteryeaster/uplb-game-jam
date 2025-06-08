extends Sprite2D

# Parallax settings
@export var parallax_strength: float = 0.1  # How much the sprite follows the mouse (0-1)
@export var smooth_speed: float = 5.0       # How smooth the movement is
@export var max_distance: float = 100.0     # Maximum distance the sprite can move from center

# Internal variables
var screen_center: Vector2
var initial_position: Vector2
var target_position: Vector2

func _ready():
	# Store the initial position and screen center
	initial_position = global_position
	screen_center = get_viewport().get_visible_rect().size / 2
	target_position = initial_position

func _process(delta):
	# Get mouse position relative to screen center
	var mouse_pos = get_global_mouse_position()
	var mouse_offset = mouse_pos - screen_center
	
	# Calculate parallax offset
	var parallax_offset = mouse_offset * parallax_strength
	
	# Clamp the offset to maximum distance
	if parallax_offset.length() > max_distance:
		parallax_offset = parallax_offset.normalized() * max_distance
	
	# Calculate target position
	target_position = initial_position + parallax_offset
	
	# Smoothly interpolate to target position
	global_position = global_position.lerp(target_position, smooth_speed * delta)

# Optional: Reset to initial position when mouse leaves the screen
func _notification(what):
	if what == NOTIFICATION_WM_MOUSE_EXIT:
		target_position = initial_position
