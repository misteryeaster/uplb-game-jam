extends Button

signal options_ui_requested




func _on_pressed() -> void:
	options_ui_requested.emit()
