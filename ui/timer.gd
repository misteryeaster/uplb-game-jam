extends Label

func _on_time_time_changed(time: float) -> void:
	var minutes: int = int(time / 60)
	var seconds: int = int(time) - minutes * 60
	
	text = ("0" if minutes < 10 else "") + str(minutes) + ":" +  ("0" if seconds < 10 else "") + str(seconds)
