@tool
extends Node3D
class_name TerrainManager

@export var regenerate_terrain := false :
	set(new_reload):
		regenerate_terrain = false
		generates_terrain()


@export var terrain_map: FastNoiseLite
@export var terrain_material: Material
@export var height: int = 1

@export_category("Chunks")
@export var chunk_count: int = 9
@export var chunk_size: Vector2 = Vector2(50,50)
@export_range(1,6) var chunk_render_distance: int = 1


@export_category("Clutter")
@export var clutter_count: int = 20000
@export var clutter_mesh: Mesh = preload("res://modules/procedural_generation/procedural_plane/grass_patch_v3.res")

var chunks: Array[ProceduralPlane] = []

# Called when the node enters the scene tree for the first time.
func _ready():
	generates_terrain()

func generates_terrain():
	# Clear existing chunks
	for chunk in chunks:
		if chunk != null:
			chunk.queue_free()  # Remove from scene
	chunks.clear()  # Empty the array

	var grid_size = int(sqrt(chunk_count))  # Ensure chunk_count is valid
	var half_grid_size = grid_size / 2.0  # Used to center the grid
	
	print("Generating chunk planes...")
	for i in range(chunk_count):
		var x = i % grid_size  # Column index
		var y = i / grid_size  # Row index

		var chunk = ProceduralPlane.new()  # Ensure ProceduralPlane is correctly defined
		chunk.size = chunk_size
		chunk.height = height
		chunk.material = terrain_material
		chunk.mesh_texture = terrain_map.duplicate()
		chunk.instance_count = max(0,clutter_count)

		# Positioning in a centered grid
		chunk.transform.origin = Vector3(
			(x - half_grid_size) * chunk_size.x + chunk_size.x / 2.0,  # Shift center
			0,
			(y - half_grid_size) * chunk_size.y + chunk_size.y / 2.0   # Shift center
		)
		self.add_child(chunk)
		chunk.generate_mesh()
		# Store the chunk in the array
		chunks.append(chunk)
		# generate clutter for each chunk	
		print("Chunk %s plane generated" % i)
	generate_clutter()

func generate_clutter():
	print("Generating clutter...")
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
			var x := randf_range(-chunk_size.x / 2.0, chunk_size.x / 2.0)
			var z := randf_range(-chunk_size.y / 2.0, chunk_size.y / 2.0)
			var y = chunk.mesh_texture.get_noise_2d(x,z)*height
			#print(chunk.mesh_texture.get_noise_2d(x,z)," - ",terrain_map.get_noise_2d(x,z))
			var transform = Transform3D()
			transform = transform.translated(Vector3(x, y, z))
			transform = transform.rotated_local(Vector3.UP,randf_range(-PI,PI))
			multi_mesh_instance.multimesh.set_instance_transform(i, transform)
		
		print("Chunk %s clutter generated" % chunk.get_index())
		
func get_terrain_height(x:float, z:float) -> float:
	return terrain_map.get_noise_2d(x,z) * height
