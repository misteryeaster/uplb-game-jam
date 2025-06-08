extends Node3D


func _on_player_was_hit() -> void:
	$AnimationPlayer.play("curse")
