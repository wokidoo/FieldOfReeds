extends SpringArm3D

@export var speed: float = 5.0

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	self.rotate(Vector3.UP,deg_to_rad(speed*delta))
