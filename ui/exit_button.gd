extends Button

signal game_exit_requested

func _on_pressed() -> void:
	game_exit_requested.emit()
