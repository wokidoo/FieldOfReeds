@tool
extends Node3D
class_name ProceduralPlane

@export var regenerate_mesh := false :
	set(new_reload):
		regenerate_mesh = false
		generate_mesh()

@export_category("Mesh")
@export var auto_regenerate: bool = false :
	set(new_val):
		auto_regenerate = new_val
		if mesh_texture and material:
			if auto_regenerate:
				mesh_texture.changed.connect(generate_mesh)
				mesh_texture.changed.connect(update_mesh_texture_offset)
				material.changed.connect(generate_mesh)
			else:
				mesh_texture.changed.disconnect(generate_mesh)
				mesh_texture.changed.disconnect(update_mesh_texture_offset)
				material.changed.disconnect(generate_mesh)
			
@export var mesh_texture: FastNoiseLite
@export var size : Vector2:
	set(new_val):
		size = new_val
		if auto_regenerate:
			generate_mesh()
@export_range(1,32) var subdivisions: int = 1:
	set(new_val):
		subdivisions = new_val
		if auto_regenerate:
			generate_mesh()
@export var material: Material
@export_range(0.0,50.0) var height: float = 1.0:
	set(new_val):
		height = new_val
		if auto_regenerate:
			generate_mesh()

@export_category("Multi mesh")
@export var instance_count: int = 20000
@export var instance_mesh: Mesh = preload("res://modules/procedural_generation/procedural_plane/grass_patch.res")

var mesh: MeshInstance3D
var multi_mesh_instance: MultiMeshInstance3D

signal terrain_change()

func _ready() -> void:
	if !material:
		material = Material.new()
	terrain_change.connect(generate_mesh)
	#generate_mesh()
	#generate_multimesh()

func generate_mesh() -> void:
	update_mesh_texture_offset()
	# remove old mesh
	if mesh:
		mesh.queue_free()
	
	print("Generating mesh data")
	# defining plane mesh
	var plane_mesh = PlaneMesh.new()
	plane_mesh.size = size
	plane_mesh.subdivide_width = size.x * subdivisions
	plane_mesh.subdivide_depth = size.y * subdivisions
	plane_mesh.material = material
	
	print("Creating mesh")
	var st = SurfaceTool.new()
	# creating vertex array from plane mesh
	st.create_from(plane_mesh,0)
	
	# Using MeshDataTool to manipulate vertex data
	var data = MeshDataTool.new()
	# Creating ArrayMesh from original plane mesh to manipulate vertices
	var array_plane = st.commit()
	data.create_from_surface(array_plane,0)
	
	# Set each vertex.y value to mesh_texture value 
	for i in range(data.get_vertex_count()):
		var vertex = data.get_vertex(i)
		vertex.y  = get_noise_y(vertex.x, vertex.z)
		data.set_vertex(i, vertex)
	
	# Clear old array_plane mesh data and set the new modified ArrayMesh
	array_plane.clear_surfaces()
	data.commit_to_surface(array_plane)
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	st.create_from(array_plane,0)
	st.generate_normals()
	
	
	mesh = MeshInstance3D.new()
	mesh.mesh =  st.commit()
	mesh.create_trimesh_collision()
	mesh.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(mesh)
	generate_multimesh()

func get_noise_y(x, z) -> float:
	return mesh_texture.get_noise_2d(x,z) * height

func generate_multimesh():
	print("Adding multimesh")
	
	# Explicitly create and initialize MultiMesh
	var multi_mesh = MultiMesh.new()
	multi_mesh.mesh = instance_mesh
	multi_mesh.transform_format = MultiMesh.TRANSFORM_3D
	multi_mesh.instance_count = instance_count

	if not instance_mesh or not multi_mesh.mesh:
		push_warning("MultiMesh or its Mesh resource is null, skipping generation.")
		return
		
	# Remove all previously generated meshes
	if multi_mesh_instance:
		for i in multi_mesh_instance.get_children():
			multi_mesh_instance.remove_child(i)
			i.queue_free()
		multi_mesh_instance.queue_free()

	# Create MultiMeshInstance3D and assign the MultiMesh resource
	multi_mesh_instance = MultiMeshInstance3D.new()
	multi_mesh_instance.multimesh = multi_mesh
	multi_mesh_instance.visibility_range_begin_margin = 10.0
	multi_mesh_instance.visibility_range_begin_margin = 50.0
	
	# IMPORTANT: Add to the scene
	add_child(multi_mesh_instance)

	# Populate transforms
	for i in range(multi_mesh.instance_count):
		var x := randf_range(-size.x / 2.0, size.x / 2.0)
		var z := randf_range(-size.y / 2.0, size.y / 2.0)
		var transform = Transform3D(Basis(), Vector3(x, get_noise_y(x, z), z))
		multi_mesh.set_instance_transform(i, transform)

	print("Multimesh successfully created!")

func update_mesh_texture_offset():
	# set texture offset to node position
	mesh_texture.offset.x = position.x
	mesh_texture.offset.y = position.z
