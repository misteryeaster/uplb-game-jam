extends Button

signal game_start_requested


func _on_pressed() -> void:
	game_start_requested.emit()
