extends Control

func _ready() -> void:
	visible = false

func _on_game_game_ended() -> void:
	visible = false

func _on_game_game_finished(time_left: float) -> void:
	$AnimationPlayer.play("enter")
	
	var minutes = int(time_left) / 60
	var seconds = int(time_left) % 60
	
	$Timer.text = "%02d:%02d" % [minutes, seconds]
