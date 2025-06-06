extends Node3D

signal depleted
signal health_changed
signal health_percentage_changed
signal player_hurt(damage: float)  # New signal for camera shake

@export var max_health: float

@onready var health: float = max_health:
	set(value):
		health = max(value, 0)
		
		health_changed.emit(health)
		health_percentage_changed.emit(health / max_health * 100)
		
		if (health > 0):
			return
			
		depleted.emit()
		
func on_hurt(damage: float) -> void:
	health -= damage
	player_hurt.emit(damage)  # Emit signal for camera shake
	
func setup():
	health = max_health
	
	health_changed.emit(health)
	health_percentage_changed.emit(health / max_health * 100)

func _ready() -> void:
	health_changed.emit(health)
	health_percentage_changed.emit(health / max_health * 100)
	
func _on_hurtbox_hurt(damage: float) -> void:
	on_hurt(damage)

func _on_player_just_reset() -> void:
	setup()
