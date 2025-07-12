extends Control

@onready var magic_bar = $MagicBar
@onready var magic_label = $MagicLabel
@onready var button = $ColorRect/Button

var max_mp = 100
var current_mp = 100
var mp_cost = 10  # Amount of magic points to decrease per button press
var tween_duration = 0.5  # Duration of the tween animation in seconds

func _ready():
	button.pressed.connect(on_button_pressed)
	update_mp_display(false)  # Initial update without animation

func on_button_pressed():
	decrease_mp(mp_cost)

func decrease_mp(amount):
	var new_mp = max(0, current_mp - amount)
	update_mp_display(true, new_mp)
	current_mp = new_mp

func update_mp_display(animate: bool, target_mp = current_mp):
	var fill_value = (float(target_mp) / float(max_mp) - 0.5) * 2.0
	
	if animate:
		var tween = create_tween()
		tween.set_parallel(true)
		
		# Animate fill value
		tween.tween_method(set_fill_value, 
						   magic_bar.material.get_shader_parameter("fill_value"), 
						   fill_value, 
						   tween_duration)
		
		# Animate label text
		tween.tween_method(set_label_text, 
						   current_mp, 
						   target_mp, 
						   tween_duration)
	else:
		# Update immediately without animation
		set_fill_value(fill_value)
		set_label_text(target_mp)

func set_fill_value(value: float):
	magic_bar.material.set_shader_parameter("fill_value", value)

func set_label_text(value: float):
	magic_label.text = str(round(value))
