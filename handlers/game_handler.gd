extends Node3D

signal game_started
signal game_ended

@onready var game_ongoing: bool = false

func is_game_ongoing() -> bool:
	return game_ongoing
	
func exit():
	print("Game exited.")
	
	get_tree().quit()

func start() -> void:
	if (game_ongoing):
		printerr("Game is already ongoing?")
		return
		
	game_started.emit()
	
	game_ongoing = true
	
	print("Game started.")
	
func end() -> void:
	if (!game_ongoing):
		printerr("Game is not ongoing?")
		return
		
	game_ended.emit()
	
	game_ongoing = false
	
	print("Game ended.")

func _on_play_button_game_start_requested() -> void:
	start()

func _on_exit_button_game_exit_requested() -> void:
	exit()
	
func _on_player_died() -> void:
	end()
