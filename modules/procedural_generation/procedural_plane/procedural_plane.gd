@tool
extends Object
## @experimental
## A utility class for generating procedural 3D terrain meshes based on noise textures.
##
## This class provides tools to procedurally generate 3D meshes ([MeshInstance3D]) using a [FastNoiseLite] texture.
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
	# Create duplicat of texure to avoid modifiying the original
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
