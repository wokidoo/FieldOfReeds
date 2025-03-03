@tool
extends Node3D
class_name TerrainManager

@export var regenerate_terrain := false :
	set(new_reload):
		regenerate_terrain = false
		generate_terrain()


@export var terrain_map: FastNoiseLite
@export var height: int = 1

@export_category("Chunks")
@export var chunk_count: int = 9
@export var chunk_size: Vector2 = Vector2(50,50)
@export var subdivisions: int = 1
@export var chunk_material: Material


@export_category("Clutter")
@export var clutter_count: int = 5000
@export var clutter_mesh: Mesh = preload("res://meshes/grass_patch_v3.res")

@export_category("Water")
@export var water_level: float = 0.0:
	set(new_val):
		if water:
			water_level = new_val
			water.position.y = water_level
			RenderingServer.global_shader_parameter_set("water_level",water_level)
@export var water_material: Material

var chunks: Array[MeshInstance3D] = []
var water: MeshInstance3D

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	RenderingServer.global_shader_parameter_set("water_level",water_level)
	generate_terrain()

func generate_terrain() -> void:
	# Clear existing chunks
	for chunk in chunks:
		if chunk != null:
			chunk.queue_free()  # Remove from scene
	chunks.clear()  # Empty the array

	var grid_size:int = int(sqrt(chunk_count))  # Ensure chunk_count is valid
	var half_grid_size:int = grid_size / 2.0  # Used to center the grid
	
	print_debug("Generating chunk meshes...")
	for i in range(chunk_count):
		var col = (i % grid_size)  # Column index
		var row = i / grid_size  # Row index
		
		var x = (col - half_grid_size)*chunk_size.x
		var z = (row - half_grid_size)*chunk_size.y

		var chunk:MeshInstance3D = ProceduralPlane.generate_mesh(terrain_map,Vector2(x,z),chunk_size,height,subdivisions,chunk_material)
		chunk.position = Vector3(x,0.0,z)
		self.add_child(chunk)
		# Store the chunk in the array
		chunks.append(chunk)
		# generate clutter for each chunk	
		print_debug("Chunk %s plane generated" % i)
	generate_clutter()
	generate_water()

func generate_clutter() -> void:
	print_debug("Generating clutter...")
	# Create multimesh resource 
	var multi_mesh_resource = MultiMesh.new()
	multi_mesh_resource.mesh = clutter_mesh
	multi_mesh_resource.transform_format = MultiMesh.TRANSFORM_3D
	multi_mesh_resource.instance_count = clutter_count
	var total_time: float =0.0
	# Iterate through each chunk
	for chunk in chunks:
		# Remove old clutter and MultiMeshInstance in each chunk
		for child in chunk.get_children():
			if child is MultiMeshInstance3D or child.is_in_group("clutter"):
				chunk.remove_child(child)
				child.queue_free()
		
		var multi_mesh_instance: MultiMeshInstance3D = MultiMeshInstance3D.new()
		multi_mesh_instance.multimesh = multi_mesh_resource.duplicate()
		multi_mesh_instance.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		multi_mesh_instance.visibility_range_begin_margin = 10.0
		multi_mesh_instance.visibility_range_begin_margin = 50.0
		multi_mesh_instance.add_to_group("clutter")
		
		# Add new MultMeshInstance to chunk
		chunk.add_child(multi_mesh_instance)
		
		for i in range(clutter_count):
			# Create temporary copy of terrain map to not modify the original texture
			var noise_tex_temp = terrain_map.duplicate()
			# Set the offset to the current chunk position to generate clutter in the right places
			noise_tex_temp.offset = Vector3(chunk.position.x,chunk.position.z,0.0)
			var x := randf_range(-chunk_size.x / 2.0, chunk_size.x / 2.0)
			var z := randf_range(-chunk_size.y / 2.0, chunk_size.y / 2.0)
			var y = noise_tex_temp.get_noise_2d(x,z)*height
			var transform = Transform3D()
			transform = transform.translated(Vector3(x, y, z))
			transform = transform.rotated_local(Vector3.UP,randf_range(-PI,PI))
			multi_mesh_instance.multimesh.set_instance_transform(i, transform)
		
		print_debug("Chunk %s clutter generated" % chunk.get_index())
		
func generate_water() -> void:
	print_debug("Generating water...")
	# Remvove old water mesh
	if water:
		water.queue_free()
	
	var water_mesh:Mesh = PlaneMesh.new()
	water_mesh.size = Vector2(1000.0,1000.0)
	water_mesh.subdivide_width = water_mesh.size.x
	water_mesh.subdivide_depth = water_mesh.size.y
	water_mesh.material = water_material
	
	# creating mesh instance using mesh data
	var st = SurfaceTool.new()
	# creating vertex array from plane mesh
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	st.create_from(water_mesh,0)
	st.generate_normals()
	
	water = MeshInstance3D.new()
	water.mesh =  st.commit()
	water.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	water.position.y = water_level
	add_child(water)
