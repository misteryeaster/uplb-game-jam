extends Label

func _ready() -> void:
	visible = false

func _on_player_picked_up(pickup_id: String) -> void:
	if (pickup_id != "energy"):
		return
		
	$AnimationPlayer.play("default")
