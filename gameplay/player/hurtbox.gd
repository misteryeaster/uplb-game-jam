extends Area3D

signal hurt

func _on_area_entered(area: Area3D) -> void:
	hurt.emit(area.damage)
