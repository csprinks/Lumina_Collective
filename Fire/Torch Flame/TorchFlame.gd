extends MeshInstance3D

var material: ShaderMaterial

func _ready():
	ensure_material()
	update_resolution()

func _on_viewport_size_changed():
	update_resolution()

func _process(delta):
	material.set_shader_parameter("time", Time.get_ticks_msec() / 1000.0)

func ensure_material():
	if material_override == null:
		material = ShaderMaterial.new()
		# Here you should set up your shader. For example:
		# material.shader = preload("res://path_to_your_shader.gdshader")
		material_override = material
	else:
		material = material_override

func update_resolution():
	if is_instance_valid(get_viewport()):
		material.set_shader_parameter("resolution", get_viewport().size)
