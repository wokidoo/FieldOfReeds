@tool
extends Object
## @experimental
## A utility class for generating procedural 3D terrain meshes based on noise textures.
##
## This class provides tools to procedurally generate and modify 3D meshes ([MeshInstance3D]) using a [FastNoiseLite] texture.
## The generated mesh includes collision data and can be customized with parameters such 
## as size, height, subdivisions, and material.
## [br][br]
## [b]Usage:[/b]
## [codeblock lang=gdscript]
## var terrain_mesh = TerrainGenerator.generate_mesh(
##     noise_texture,
##     Vector2(0, 0),
##     Vector2(10, 10),
##     5.0,
##     4,
##     material
## )
## add_child(terrain_mesh)
## [/codeblock]
##
## [b]Note:[/b] This class is designed for procedural terrain generation and may require further optimization for very large terrains.
class_name ProceduralPlane

## Generates a 3D plane using a noise texture.
## [br]
## [br]- [param noise_texture]: The [FastNoiseLite] instance used to generate heightmap data.
## [br]- [param texture_offset]: A 2D vector specifying the offset of the noise texture for seamless stitching.
## [br]- [param size]: A 2D vector defining the width and depth of the plane mesh.
## [br]- [param height]: The displacement for the vertices based on the noise texture.
## [br]- [param subdivisions]: The number of subdivisions per unit of the plane mesh (controls vertex density).
## [br]- [param material]: The material to apply to the generated mesh.
static func generate_mesh(
	noise_texture:FastNoiseLite, 
	texture_offset: Vector2, 
	size:Vector2, 
	height:float, 
	subdivisions:int, 
	material:Material) -> MeshInstance3D:
	# Create duplicate of texure to avoid modifiying the original
	var noise_tex_temp:FastNoiseLite = noise_texture.duplicate()
	# Set temp noise texture offset so the mesh can be stitched with other planes
	noise_tex_temp.offset= Vector3(texture_offset.x,texture_offset.y,0.0)
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
		mesh_vertex.y  = noise_tex_temp.get_noise_2d(mesh_vertex.x, mesh_vertex.z) * height
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

## @experimental: This method is subject to major change
## Finds the index of the nearest vertex to a given position in a MeshInstance3D.
##
## This function searches for the closest vertex in the given `MeshInstance3D` using a
## [b]greedy nearest-neighbor[/b] algorithm. The search starts from the first vertex
## and iteratively moves to the closest connected vertex until no closer vertex
## is found. Optionally, it can convert a global position to local space before
## performing the search.
## [br][br]
## [b][color=gold]Note:[/color][/b] The current implementation of the greedy search 
## algorithm will eventually replaced with one of the following in order to both improve
## runtime efficiency and avoid bugs...
## [br][b]- k-d Tree (binary space partitioning tree)[/b]
## [br][b]- BVH (Bounding Volume Hierarchy)[/b]
## [br][b]- Grid Partitioning + Local k-d Tree[/b]
## 
## [br][br]
## [param target_mesh]: The `MeshInstance3D` whose vertex data is searched.
## [br]
## [param target_position]: The position in either global or local space to compare against.
## [br]
## [param global_space]: If `true`, `target_position` is assumed to be in global space 
##                     and will be converted to local space before searching. Defaults to `true`.
static func get_nearest_index(target_mesh:MeshInstance3D,target_position: Vector3, global_space: bool = true) -> int:
	# If the target postion is in global space, convert to local space
	if global_space:
		target_position = target_mesh.to_local(target_position)
	
	var mdt: MeshDataTool = MeshDataTool.new()
	# Load mesh data
	mdt.create_from_surface(target_mesh.mesh, 0)  
	
	# Start search from the first vertex in the array
	var current_index = 0  
	var current_distance = mdt.get_vertex(current_index).distance_to(target_position)

	while true:
		var nearest_index = current_index
		var shortest_distance = current_distance
		# Track if we find a closer vertex
		var found_closer = false

		# Iterate over connected edges
		for edge_index in mdt.get_vertex_edges(current_index):
			var vert_index_0 = mdt.get_edge_vertex(edge_index, 0)
			var vert_index_1 = mdt.get_edge_vertex(edge_index, 1)

			# Find the vertex that is NOT the current one (i.e., the connected vertex)
			var next_index = vert_index_0 if vert_index_1 == current_index else vert_index_1
			var next_distance = mdt.get_vertex(next_index).distance_to(target_position)

			# If this vertex is closer, update the next step
			if next_distance < shortest_distance:
				nearest_index = next_index
				shortest_distance = next_distance
				found_closer = true

		# If no closer vertex is found, stop searching
		if not found_closer:
			break

		# Move to the newly found closest vertex
		current_index = nearest_index
		current_distance = shortest_distance
	return current_index
