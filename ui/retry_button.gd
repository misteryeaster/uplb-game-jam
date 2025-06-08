extends Button

signal game_restart_requested

func _on_pressed() -> void:
	game_restart_requested.emit()
