# EnergyBuffBar.gd
extends Control

@onready var progress_bar: ProgressBar = $ProgressBar

var max_duration: float = 0.0
var current_duration: float = 0.0
var is_active: bool = false

func _ready():
	# Hide the bar initially
	visible = false
	
	# Optional: Add a slight delay before showing to let pickup notification play first
	modulate.a = 0.0

func show_energy_buff(duration: float):
	max_duration = duration
	current_duration = duration
	is_active = true
	visible = true
	
	# Set up the progress bar
	progress_bar.max_value = max_duration
	progress_bar.value = current_duration
	
	# Fade in smoothly (optional - gives a nice transition after pickup notification)
	var tween = create_tween()
	tween.tween_property(self, "modulate:a", 1.0, 0.3)

func update_energy_buff(remaining_time: float):
	if not is_active:
		return
		
	current_duration = remaining_time
	progress_bar.value = current_duration
	
	# Hide when duration reaches 0
	if current_duration <= 0:
		hide_energy_buff()

func hide_energy_buff():
	if not is_active:
		return
		
	is_active = false
	current_duration = 0.0
	
	# Fade out smoothly
	var tween = create_tween()
	tween.tween_property(self, "modulate:a", 0.0, 0.3)
	tween.tween_callback(func(): visible = false)

func reset_energy_buff(new_duration: float):
	# Called when energy effect is refreshed
	max_duration = new_duration
	current_duration = new_duration
	progress_bar.value = current_duration
