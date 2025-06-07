extends Area3D

signal picked_up


func _on_area_entered(area: Area3D) -> void:
	if (area is not Pickup):
		return
		
	picked_up.emit(area.id)
	area.on_pickup()
