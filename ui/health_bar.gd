extends ProgressBar

@onready var actual_value: float

func _on_health_health_percentage_changed(health_percent: float) -> void:
	actual_value = health_percent
	
func _process(delta: float) -> void:
	value = lerp(value, actual_value, 10 * delta)

func _on_game_game_ended() -> void:
	value = 100
