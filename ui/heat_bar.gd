extends ProgressBar

@onready var actual_value: float = 100.0  # Start at full health
@onready var style_fill: StyleBoxFlat
@onready var pulse_tween: Tween
@onready var is_pulsing: bool = false

func _ready():
	style_fill = get_theme_stylebox("fill").duplicate()
	add_theme_stylebox_override("fill", style_fill)
	
func _on_heat_heat_percentage_changed(heat_percent: float) -> void:
	actual_value = heat_percent
	
	update_bar_color(heat_percent)
	
func update_bar_color(percent: float):
	var bar_color: Color
	var text_color: Color
	
	if percent > 70:
		bar_color = Color(0.2, 0.8, 0.2)  # Green
		text_color = Color.WHITE
	elif percent > 40:
		bar_color = Color(0.9, 0.8, 0.1)  # Yellow
		text_color = Color.BLACK  # Black text on yellow
	elif percent > 20:
		bar_color = Color(1.0, 0.5, 0.1)  # Orange
		text_color = Color.WHITE
	else:
		bar_color = Color(0.9, 0.2, 0.2)  # Red
		text_color = Color.WHITE
		if !is_pulsing:
			start_critical_pulse()
	
	style_fill.bg_color = bar_color
	add_theme_color_override("font_color", text_color)

func start_critical_pulse():
	if pulse_tween:
		pulse_tween.kill()
	
	is_pulsing = true
	pulse_tween = create_tween()
	pulse_tween.set_loops(-1)
	pulse_tween.tween_property(self, "modulate:a", 0.5, 0.5)
	pulse_tween.tween_property(self, "modulate:a", 1.0, 0.5)

func stop_critical_pulse():
	if pulse_tween:
		pulse_tween.kill()
	is_pulsing = false
	modulate.a = 1.0
	
func _process(delta: float) -> void:
	value = lerp(value, actual_value, 10 * delta)
	
	# Stop pulsing when health recovers
	if actual_value > 20:
		stop_critical_pulse()

func _on_game_game_ended() -> void:
	stop_critical_pulse()


func _on_game_game_started() -> void:
	actual_value = 0
	value = 0
	update_bar_color(0)
