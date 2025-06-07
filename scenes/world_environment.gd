extends WorldEnvironment

# References to your heat handler node
@export var heat_handler_path: NodePath
@onready var heat_handler: Node3D

# Visual effect ranges - adjust these to your liking
@export_group("Brightness Settings")
@export var min_brightness: float = 1.0  # Normal brightness at 0 heat
@export var max_brightness: float = 0.8  # Maximum brightness at max heat

@export_group("Contrast Settings")
@export var min_contrast: float = 1.0    # Normal contrast at 0 heat
@export var max_contrast: float = 0.8    # Maximum contrast at max heat

@export_group("Saturation Settings")
@export var min_saturation: float = 1.0  # Normal saturation at 0 heat
@export var max_saturation: float = 0.6  # Desaturated at max heat (creates washed out look)

# Optional: Color tint for extreme heat
@export_group("Heat Tint Settings")
@export var enable_heat_tint: bool = true
@export var heat_tint_color: Color = Color(1.0, 0.8, 0.6, 1.0)  # Warm orange tint
@export var heat_tint_threshold: float = 0.7  # Start tinting at 70% heat

func _ready() -> void:
	# Get reference to heat handler
	if heat_handler_path.is_empty():
		# Try to find heat handler automatically
		heat_handler = get_node("../HeatHandler") # Adjust path as needed
	else:
		heat_handler = get_node(heat_handler_path)
	
	# Connect to heat signals
	if heat_handler:
		heat_handler.heat_percentage_changed.connect(_on_heat_percentage_changed)
		print("Connected to heat handler successfully")
	else:
		print("Warning: Could not find heat handler node")
	
	# Initialize environment if it doesn't exist
	if not environment:
		environment = Environment.new()

func _on_heat_percentage_changed(heat_percentage: float) -> void:
	# Normalize heat percentage (0.0 to 1.0)
	var heat_factor = heat_percentage / 100.0
	heat_factor = clamp(heat_factor, 0.0, 1.0)
	
	# Apply brightness adjustment
	var target_brightness = lerp(min_brightness, max_brightness, heat_factor)
	environment.adjustment_brightness = target_brightness
	
	# Apply contrast adjustment
	var target_contrast = lerp(min_contrast, max_contrast, heat_factor)
	environment.adjustment_contrast = target_contrast
	
	# Apply saturation adjustment
	var target_saturation = lerp(min_saturation, max_saturation, heat_factor)
	environment.adjustment_saturation = target_saturation

# Optional: Add smooth transitions
func smooth_adjust_environment(target_brightness: float, target_contrast: float, target_saturation: float, duration: float = 0.5) -> void:
	var tween = create_tween()
	tween.set_parallel(true)  # Allow multiple properties to tween simultaneously
	
	tween.tween_property(environment, "adjustment_brightness", target_brightness, duration)
	tween.tween_property(environment, "adjustment_contrast", target_contrast, duration)
	tween.tween_property(environment, "adjustment_saturation", target_saturation, duration)
