@tool
extends Node3D
class_name TerrainManager

@export var regenerate_terrain := false :
	set(new_reload):
		regenerate_terrain = false
		generates_chunks()


@export var terrain_map: FastNoiseLite
@export var terrain_material: Material
@export var height: int = 1
@export var chunk_count: int = 9

@export_category("Chunks")
@export var chunk_size: Vector2 = Vector2(50,50)
@export_range(1,6) var chunk_render_distance: int = 1
@export var clutter_per_chunk: int = 20000

var chunks: Array[ProceduralPlane] = []

# Called when the node enters the scene tree for the first time.
func _ready():
	generates_chunks()

func generates_chunks():
	# Clear existing chunks
	for chunk in chunks:
		if chunk != null:
			chunk.queue_free()  # Remove from scene
	chunks.clear()  # Empty the array

	var grid_size = int(sqrt(chunk_count))  # Ensure chunk_count is valid
	var half_grid_size = grid_size / 2.0  # Used to center the grid
	
	for i in range(chunk_count):
		var x = i % grid_size  # Column index
		var y = i / grid_size  # Row index

		var chunk = ProceduralPlane.new()  # Ensure ProceduralPlane is correctly defined
		chunk.size = chunk_size
		chunk.height = height
		chunk.material = terrain_material
		chunk.mesh_texture = terrain_map.duplicate()
		chunk.instance_count = max(0,clutter_per_chunk)

		# Positioning in a centered grid
		chunk.transform.origin = Vector3(
			(x - half_grid_size) * chunk_size.x + chunk_size.x / 2.0,  # Shift center
			0,
			(y - half_grid_size) * chunk_size.y + chunk_size.y / 2.0   # Shift center
		)

		self.add_child(chunk)
		chunk.generate_mesh()

		chunks.append(chunk)  # Store the chunk in the array
