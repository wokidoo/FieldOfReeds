## TerrainManager
## @experimental
## Manages procedural generation of terrain, clutter (e.g., grass patches), and water surfaces in a 3D environment.
## This class is designed to be used as a tool script for real-time updates in the Godot Editor.
@tool
extends Node3D
class_name TerrainManager

@export_tool_button("Regenerate Terrain", "CollisionShape3D") var regenerate_terrain:Callable = generate_terrain

@export_tool_button("Regenerate Clutter", "MultiMeshInstance3D") var regenerate_clutter:Callable = generate_clutter

## The noise map used for terrain height generation.
@export var terrain_maps: Array[TerrainMap]

@export var tapper_start: float = 100.0
@export var tapper_offset: float = 25.0

@export_category("Chunks")
## The total number of terrain chunks to generate.
@export var chunk_count: int = 9
## The size of individual terrain chunks (width and depth).
@export var chunk_size: Vector2 = Vector2(50,50)
## Number of subdivisions for the terrain mesh. Higher values increase detail but reduce performance.
@export var subdivisions: int = 1
## Material applied to the mesh of terrain chunks.
@export var chunk_material: Material

@export_category("Clutter")
## Total number of clutter instances per chunk.
@export var clutter_count: int = 5000
## Mesh used for clutter instances (e.g., grass patches).
@export var clutter_mesh: Mesh = preload("res://meshes/grass_patch_v3.res")
## Minimum height cutoff for clutter placement. Clutter will not appear below this height.
@export var clutter_height_cutoff: float = 0.0:
	set(new_val):
		clutter_height_cutoff = new_val
		call_deferred("generate_clutter")
## The variance for the clutter cutoff
@export var clutter_height_noise: float = 0.0:
	set(new_val):
		clutter_height_noise = new_val
		call_deferred("generate_clutter")

@export_category("Water")
## Height of the water surface in the scene.
@export var water_level: float = 0.0:
	set(new_val):
		if water:
			water_level = new_val
			water.position.y = water_level
			RenderingServer.global_shader_parameter_set("water_level",water_level)
## Material applied to the water surface.
@export var water_material: Material

## Array storing references to all generated terrain chunks.
var chunks: Array[MeshInstance3D] = []
## Reference to the water surface mesh instance.
var water: MeshInstance3D

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	RenderingServer.global_shader_parameter_set("water_level",water_level)
	generate_terrain()

## Generates terrain chunks based on the configured parameters (`chunk_count`, `chunk_size`, etc.).
## Clears any existing chunks before generating new ones.
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

		var chunk:MeshInstance3D = generate_mesh(terrain_maps,Vector2(x,z),chunk_size,subdivisions,chunk_material)
		chunk.position = Vector3(x,0.0,z)
		self.add_child(chunk)
		# Store the chunk in the array
		chunks.append(chunk)
		# generate clutter for each chunk	
		print_debug("Chunk %s plane generated" % i)
	generate_clutter()
	generate_water()

## Generates a 3D plane using a noise texture.
## [br]
## [br]- [param noise_texture]: The [FastNoiseLite] instance used to generate heightmap data.
## [br]- [param texture_offset]: A 2D vector specifying the offset of the noise texture for seamless stitching.
## [br]- [param size]: A 2D vector defining the width and depth of the plane mesh.
## [br]- [param height]: The displacement for the vertices based on the noise texture.
## [br]- [param subdivisions]: The number of subdivisions per unit of the plane mesh (controls vertex density).
## [br]- [param material]: The material to apply to the generated mesh.
func generate_mesh(
	terrain_maps:Array[TerrainMap], 
	texture_offset: Vector2, 
	size:Vector2,  
	subdivisions:int, 
	material:Material) -> MeshInstance3D:
	# Create duplicate of texure to avoid modifiying the original
	var terrain_maps_temp: Array[TerrainMap] = terrain_maps.duplicate()
	# Set temp terrain_map noise offset so the mesh can be stitched with other planes
	for terrain_map in terrain_maps_temp:
		terrain_map.noise_map.offset= Vector3(texture_offset.x,texture_offset.y,0.0)
	print_debug("Generating mesh data")
	# create flat plane mesh as a base
	var plane_mesh = PlaneMesh.new()
	plane_mesh.size = size
	plane_mesh.subdivide_width = size.x * subdivisions
	plane_mesh.subdivide_depth = size.y * subdivisions
	plane_mesh.material = material
	
	print_debug("Creating mesh")
	var st = SurfaceTool.new()
	# creating vertex array from plane mesh
	st.create_from(plane_mesh,0)
	# Creating ArrayMesh from original plane mesh to manipulate vertices
	var array_plane:ArrayMesh = st.commit()
	
	var mesh_data_tool = MeshDataTool.new()
	# Using MeshDataTool to manipulate vertex data
	mesh_data_tool.create_from_surface(array_plane,0)
	
	# Set each vertex.y value to mesh_texture value 
	for i in range(mesh_data_tool.get_vertex_count()):
		var mesh_vertex:Vector3 = mesh_data_tool.get_vertex(i)
		mesh_vertex.y = get_total_map_height(Vector2(mesh_vertex.x,mesh_vertex.z),texture_offset)
		# tapper down height as you get further from center
		var tapper : float = get_center_lerp(mesh_vertex,texture_offset)
		var center_distance: float = get_center_distance(mesh_vertex,texture_offset)
		#mesh_vertex.y *= tapper
		if is_zero_approx(tapper):
			var reduce_by: float = center_distance - (tapper_offset+ tapper_start) 
			mesh_vertex.y -= reduce_by
		mesh_data_tool.set_vertex(i, mesh_vertex)
	
	# Clear old array_plane mesh data and set the new modified ArrayMesh
	array_plane.clear_surfaces()
	# Update ArrayMesh with updated vertex data
	mesh_data_tool.commit_to_surface(array_plane)
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	st.create_from(array_plane,0)
	st.generate_normals()
	
	
	var mesh = MeshInstance3D.new()
	# Create mesh with SurfaceTool
	mesh.mesh =  st.commit()
	# Create collision for mesh
	mesh.create_trimesh_collision()
	mesh.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	return mesh

## Generates clutter (e.g., grass patches) for each terrain chunk based on configured parameters.
## Removes old clutter before generating new instances.
func generate_clutter() -> void:
	print_debug("Generating clutter...")
	# Iterate through each chunk
	for chunk in chunks:
		# Remove old clutter and MultiMeshInstance in each chunk
		for child in chunk.get_children():
			if child is MultiMeshInstance3D or child.is_in_group("clutter"):
				chunk.remove_child(child)
				child.queue_free()

		# Create a new MultiMesh resource for this chunk
		var multi_mesh_resource = MultiMesh.new()
		multi_mesh_resource.mesh = clutter_mesh
		multi_mesh_resource.transform_format = MultiMesh.TRANSFORM_3D

		# Temporary list to store valid transforms
		var valid_transforms: Array[Transform3D] = []

		for i in range(clutter_count):
			# Generate random position within the chunk
			var x := randf_range(-chunk_size.x / 2.0, chunk_size.x / 2.0)
			var z := randf_range(-chunk_size.y / 2.0, chunk_size.y / 2.0)
			var y := get_total_map_height(Vector2(x,z),Vector2(chunk.global_position.x,chunk.global_position.z))
			y *= get_center_lerp(Vector3(x,y,z),Vector2(chunk.global_position.x,chunk.global_position.z))
			# Check if the position is above the water level
			if y >= clutter_height_cutoff + randf_range(-clutter_height_noise,clutter_height_noise):
				var transform = Transform3D()
				transform.origin = Vector3(x, y, z)
				transform = transform.rotated_local(Vector3.UP, randf_range(-PI, PI))
				valid_transforms.append(transform)

		# Set instance count based on valid transforms
		multi_mesh_resource.instance_count = valid_transforms.size()

		# Assign transforms to MultiMesh instances
		for i in range(valid_transforms.size()):
			multi_mesh_resource.set_instance_transform(i, valid_transforms[i])

		# Create MultiMeshInstance and add it to the chunk
		var multi_mesh_instance: MultiMeshInstance3D = MultiMeshInstance3D.new()
		multi_mesh_instance.multimesh = multi_mesh_resource
		multi_mesh_instance.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		multi_mesh_instance.add_to_group("clutter")
		chunk.add_child(multi_mesh_instance)

		print_debug("Chunk %s clutter generated" % chunk.get_index())

## Generates a water surface at the configured `water_level`.
## Removes any existing water surface before creating a new one.
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

func get_total_map_height(position: Vector2, offset: Vector2) -> float:
	var height: float = 0.0
	for terrain_map in terrain_maps:
		var noise:FastNoiseLite = terrain_map.noise_map
		noise.offset.x = offset.x
		noise.offset.y = offset.y
		height += noise.get_noise_2d(position.x,position.y) * terrain_map.height
	return height

func get_center_lerp(position: Vector3, offset: Vector2) -> float:
	var center_distance = get_center_distance(position,offset)
	var lerp = inverse_lerp(tapper_offset+tapper_start, tapper_start, center_distance)
	return clamp(lerp,0.0,1.0)

func get_center_distance(position: Vector3, offset: Vector2) -> float:
	var world_mesh_vertex: Vector2
	world_mesh_vertex.x = position.x + offset.x
	world_mesh_vertex.y = position.z + offset.y
	return world_mesh_vertex.distance_to(Vector2.ZERO)
	
