extends Timer

signal expired

@export var id: String
@export var duration: float

func _ready() -> void:
	start(duration)

func _on_timeout() -> void:
	expired.emit(id)
	queue_free()
