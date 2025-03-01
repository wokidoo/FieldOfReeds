extends GPUParticles3D

# Target Node3D to follow (usually the player)
@export var follow_target: Node3D

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	position = follow_target.position
