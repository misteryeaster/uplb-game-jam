extends Area3D

signal hurt

func _on_area_entered(area: Area3D) -> void:
	hurt.emit(area.damage)
	
	$Timer.start()
	
	$CollisionShape3D.set_deferred("disabled", true)


func _on_timer_timeout() -> void:
	$CollisionShape3D.set_deferred("disabled", false)
