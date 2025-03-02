extends MultiMeshInstance3D
class_name ClutterManager

@export var size: Vector2 = Vector2(50,50)
@export var height: float = 10.0
@export var texture_ref: Texture2D


func generate_multimesh():
	print("Adding clutter")

	# Explicitly create and initialize MultiMesh
	var multi_mesh_resource = MultiMesh.new()
	multi_mesh_resource.mesh = instance_mesh
	multi_mesh_resource.transform_format = MultiMesh.TRANSFORM_3D
	multi_mesh_resource.instance_count = instance_count

	if self.mesh:
		push_warning("MultiMesh or its Mesh resource is null, skipping generation.")
		return
		
	# Remove all previously generated meshes
	for i in self.get_children():
		self.remove_child(i)
		i.queue_free()
	
	if not instance_mesh:
		push_warning("instance_mesh is null")
		return
	elif not texture_ref:
		push_warning("texture_ref is mull")
		return

	# Assign the MultiMesh resource
	self.multimesh = multi_mesh_resource
	self.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	self.visibility_range_begin_margin = 10.0
	self.visibility_range_begin_margin = 50.0
	
	# Populate transforms
	for i in range(self.instance_count):
		var x := randf_range(-size.x / 2.0, size.x / 2.0)
		var z := randf_range(-size.y / 2.0, size.y / 2.0)
		var transform = Transform3D(Basis(), Vector3(x, get_noise_y(x, z,texture_ref), z))
		transform = transform.rotated(Vector3.UP,randf_range(-3.14159,3.14159))
		transform.origin = Vector3(x,get_noise_y(x,z,texture_ref),z)
		self.multimesh.set_instance_transform(i, transform)

	print("Multimesh successfully created!")

func get_noise_y(x:float, z:float, texture:Texture2D) -> float:
	return texture.get_noise_2d(x,z) * height
