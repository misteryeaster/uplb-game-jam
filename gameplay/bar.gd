extends Node2D

@export var offset: float = 1

@onready var handlers: Node2D = get_tree().current_scene.get_node("Handlers")

@onready var audio_input_handler: Node2D = handlers.get_node("AudioInput")

func _process(delta: float) -> void:
	var mic_volume: float = audio_input_handler.get_volume()
