extends Node2D

func start_game():
	get_tree().change_scene_to_file("res://scenes/main.tscn")

func _input(event: InputEvent) -> void:
	if (event is not InputEventKey):
		return
		
	if (event.echo):
		return
		
	if (event.keycode != KEY_SPACE):
		return
		
	start_game()
