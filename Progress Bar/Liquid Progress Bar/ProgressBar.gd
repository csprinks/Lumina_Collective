extends Control

@onready var health_label = $MarginContainer/Health
@onready var health_mesh = $MarginContainer/Health/HealthMesh
@onready var monster_attack_button = %MonsterAttack
@onready var game_over_label = $GameOver

var max_health = 100
var current_health = 100
var tween_duration = 0.5

func _ready():
	update_health_display(false)
	monster_attack_button.pressed.connect(on_monster_attack)
	game_over_label.visible = false

# Handle monster attack event
func on_monster_attack():
	var damage_percent = randf_range(5, 20)
	var damage = ceil(max_health * damage_percent / 100)
	current_health = max(0, current_health - damage)
	update_health_display(true, current_health)

# Update health display with optional animation
func update_health_display(animate: bool = true, target_health: int = current_health):
	var health_percentage = float(target_health) / max_health
	
	if animate:
		create_tween_animation(health_percentage, target_health)
	else:
		# Immediate update
		set_health_label(target_health)
		set_health_percentage(health_percentage)
		check_game_over(target_health)

# Create tween animation for health changes
func create_tween_animation(health_percentage: float, target_health: int):
	var tween = create_tween().set_parallel(true)
	
	# Animate health label
	tween.tween_method(
		func(value): set_health_label(value), 
		current_health, 
		target_health, 
		tween_duration
	)
	
	# Animate health bar if mesh exists
	if health_mesh:
		var material = get_health_mesh_material()
		if material:
			var start_percentage = material.get_shader_parameter("percentage")
			tween.tween_method(
				func(value): material.set_shader_parameter("percentage", value),
				start_percentage,
				health_percentage,
				tween_duration
			)
	
	# Check game over after animation completes
	tween.finished.connect(
		func(): check_game_over(target_health), 
		CONNECT_ONE_SHOT
	)

# Update health text display
func set_health_label(value: float):
	health_label.text = "%d/%d" % [round(value), max_health]

# Update health bar shader parameter
func set_health_percentage(value: float):
	var material = get_health_mesh_material()
	if material:
		material.set_shader_parameter("percentage", value)

# Get active material from health mesh
func get_health_mesh_material():
	if not health_mesh:
		return null
	
	# Check different material sources in priority order
	if health_mesh.get_surface_override_material(0):
		return health_mesh.get_surface_override_material(0)
	elif health_mesh.get_material_override():
		return health_mesh.get_material_override()
	elif health_mesh.mesh and health_mesh.mesh.surface_get_material(0):
		return health_mesh.mesh.surface_get_material(0)
	
	return null

# Check and handle game over condition
func check_game_over(health_value: int):
	if health_value <= 0:
		game_over_label.visible = true
		monster_attack_button.disabled = true
