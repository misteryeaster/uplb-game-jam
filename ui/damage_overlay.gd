# damage_overlay.gd
extends ColorRect

@export var damage_color: Color = Color(1, 0, 0, 0.6)  # Red with transparency
@export var fade_duration: float = 1.0

@onready var tween: Tween

func _ready():
	# Start completely transparent
	color = Color(1, 0, 0, 0)
	
	# Cover the whole screen
	anchor_left = 0
	anchor_top = 0
	anchor_right = 1
	anchor_bottom = 1
	
	# Make sure it's on top but doesn't block input
	mouse_filter = Control.MOUSE_FILTER_IGNORE

func show_damage_effect():
	print("Showing damage overlay effect")
	
	# Stop any existing tween
	if tween:
		tween.kill()
	
	# Create new tween
	tween = create_tween()
	
	# Flash to red then fade out
	color = damage_color
	tween.tween_property(self, "color", Color(1, 0, 0, 0), fade_duration)

# Connect this to the health system
func _on_health_player_hurt(damage: float):
	show_damage_effect()
