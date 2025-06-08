extends Node3D

signal heat_changed
signal heat_percentage_changed

@export var heat_increase: float
@export var max_heat: float = 100

@onready var heat: float = 0:
	set(value):
		heat = clamp(value, 0, max_heat)
		
		heat_changed.emit(heat)
		heat_percentage_changed.emit(heat / max_heat * 100)
		
@onready var game_ongoing: bool = false
		
func _process(delta: float) -> void:
	if (!game_ongoing):
		return
		
	heat += heat_increase * delta

func _on_game_game_started() -> void:
	heat = 0
	
	game_ongoing = true

func _on_game_game_ended() -> void:
	game_ongoing = false

func _on_player_cooled(cool_amount: float) -> void:
	heat -= cool_amount
