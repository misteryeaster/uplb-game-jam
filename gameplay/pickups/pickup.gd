extends Area3D

class_name Pickup

@export var id: String

func on_pickup():
	queue_free()
