extends Node2D

@onready var record_idx: int = AudioServer.get_bus_index("Record")

func get_volume() -> float:
	var volume: float = AudioServer.get_bus_peak_volume_left_db(record_idx, 0)
	
	return volume
	
func _process(delta: float) -> void:
	pass
