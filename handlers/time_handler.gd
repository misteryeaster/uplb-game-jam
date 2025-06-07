extends Node3D

signal time_changed

@onready var time_elapsed: float = 0

@onready var start_time: float = Time.get_unix_time_from_system()

@onready var game_started: bool = false

func get_current_time() -> float:
	return Time.get_unix_time_from_system()

func start():
	start_time = Time.get_unix_time_from_system()
	time_elapsed = 0

func _on_game_game_started() -> void:
	game_started = true
	
	start()
	
func _process(delta: float) -> void:
	time_elapsed = get_current_time() - start_time
	
	time_changed.emit(time_elapsed)
