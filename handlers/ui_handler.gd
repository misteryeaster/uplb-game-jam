extends CanvasLayer

@onready var damage_overlay: ColorRect
@onready var damage_tween: Tween

func _ready():
	damage_overlay = ColorRect.new()
	damage_overlay.color = Color(1, 0, 0, 0)
	damage_overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	damage_overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(damage_overlay)

func _on_health_player_hurt(damage):
	if damage_tween:
		damage_tween.kill()
	
	damage_tween = create_tween()
	damage_overlay.color = Color(1, 0, 0, 0.4)
	damage_tween.tween_property(damage_overlay, "color", Color(1, 0, 0, 0), 0.8)
