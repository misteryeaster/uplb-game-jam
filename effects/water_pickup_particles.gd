extends GPUParticles3D

func _ready():
	var timer = Timer.new()
	timer.wait_time = lifetime + 1.0
	timer.one_shot = true
	timer.timeout.connect(_on_cleanup)
	add_child(timer)
	timer.start()

func _on_cleanup():
	queue_free()
