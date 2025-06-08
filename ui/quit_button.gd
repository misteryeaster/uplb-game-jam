extends Button

signal game_quit_requested

func _on_pressed() -> void:
	game_quit_requested.emit()
