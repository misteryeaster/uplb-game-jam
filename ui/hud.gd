extends Control

func _ready() -> void:
	visible = false

func _on_game_game_started() -> void:
	visible = true


func _on_game_game_ended() -> void:
	visible = false

func _on_game_game_finished(_time_left: float) -> void:
	visible = false
