@warning_ignore("empty_file")
## Script not being used 

#extends Node3D
#
#@onready var ocean_mesh: MeshInstance3D = $MeshInstance3D
#@onready var death_area: Area3D = $Area3D
#
#func _ready():
	#await get_tree().process_frame  # Wait for one frame to ensure all nodes are ready
	#setup_death_area()
	#if death_area:
		#await get_tree().create_timer(1.0).timeout
		#death_area.body_entered.connect(_on_body_entered)
#
#func setup_death_area():
	#if not ocean_mesh:
		#push_error("Ocean: ocean_mesh is null")
		#return
	#
	#if not ocean_mesh.mesh:
		#push_error("Ocean: ocean_mesh.mesh is null")
		#return
#
	#var area_shape = BoxShape3D.new()
	#var mesh_size = ocean_mesh.mesh.get_aabb().size
	#area_shape.size = Vector3(mesh_size.x, 2.0, mesh_size.z)  # 2.0 units tall
#
	#var collision_shape = CollisionShape3D.new()
	#collision_shape.shape = area_shape
#
	#if not death_area:
		#push_error("Ocean: death_area is null")
		#return
	#death_area.add_child(collision_shape)
	#print("Ocean: Added CollisionShape3D to death_area")
#
	## Position the area to sit just at and above the ocean surface
	#death_area.position = Vector3(0, 0.5, 0)  # Adjust as needed
	#print("Ocean: Set death_area position to: ", death_area.position)
#
#func _on_body_entered(body):
	#print("Ocean: Body entered death area: ", body.name)
	#if body is Player:  # Make sure you have a Player class defined
		#print("Ocean: Player entered death area, setting HP to 0")
		#var active_characters = PartyManager.get_active_characters()
		#for char_id in active_characters:
			#CharacterStats.set_hit_points(char_id, 0)
		## The Death_Manager will be triggered automatically when HP reaches 0
	#else:
		#print("Ocean: Non-player body entered death area")
