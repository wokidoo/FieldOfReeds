extends CharacterBody3D

@onready var camera_arm: SpringArm3D = %CameraArm
@onready var camera_hori_offset: SpringArm3D = %CameraHorizontalOffset
@onready var camera_vert_offset: SpringArm3D = %CameraVerticalOffset
@onready var camera: Camera3D = %Camera3D
@onready var body_mesh:MeshInstance3D = $body_mesh

@export var GRAVITY: float = 9.8
@export_category("MOVEMENT")
@export var MAX_SPEED: float = 7.5
@export var ROTATE_SPEED: float = 10.0
@export_category("CAMERA")
@export var CAM_OFFSET: Vector3 = Vector3(0.0,1.0,0.0):
	set(value):
		CAM_OFFSET = value
		if camera_arm:
			tween_cam_offset()
@export_subgroup("YAW")
@export var YAW_SENSITIVITY: float = 1500.0
@export var INVERT_YAW: bool = false
@export_subgroup("PITCH")
@export var PITCH_SENSITIVITY: float = 1500.0
@export var INVERT_PITCH: bool = false
@export var PITCH_LIMITS: Vector2 = Vector2(-75.0,75.0)

var move_direction: Vector3 = Vector3.ZERO
var pitch: float = 0.0 # Track pitch separately
func _ready():
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	# Set camera arm offset
	tween_cam_offset()
	
func _physics_process(delta):
	# get new move_direciton
	var input_direction = Input.get_vector("move_left","move_right","move_backward","move_forward")
	var cam_basis_z = camera_arm.basis.z.normalized()
	var cam_basis_x = camera_arm.basis.x.normalized()
	# combine input_direction to move_direction for player to move relative to forward direction
	move_direction = cam_basis_x * input_direction.x - cam_basis_z * input_direction.y
	
	velocity.x = move_direction.x * MAX_SPEED
	velocity.z = move_direction.z * MAX_SPEED
	
	# Apply gravity
	if not is_on_floor():
		velocity.y -= GRAVITY * delta
	else:
		velocity.y = -0.1 # small downward force to keep grounded
	
	move_and_slide()
	# rotate body towards the move_direction
	if not move_direction.is_zero_approx():
		var target_rotation = Transform3D().looking_at(move_direction.normalized(), Vector3.UP).basis
		body_mesh.transform.basis = body_mesh.transform.basis.slerp(target_rotation, ROTATE_SPEED * delta)
	
func _input(event):
	if event is InputEventMouseMotion:
		# get mouse motion
		var mouse_motion: Vector2 = event.relative
		
		# Apply yaw rotation
		var yaw_inversion = 1.0 if INVERT_YAW else -1.0
		camera_arm.rotate_y(mouse_motion.x / YAW_SENSITIVITY * yaw_inversion)
		
		# Apply pitch rotation
		var pitch_inversion = 1.0 if INVERT_YAW else -1.0
		pitch += mouse_motion.y / PITCH_SENSITIVITY * pitch_inversion
		pitch = clamp(pitch, deg_to_rad(PITCH_LIMITS.x), deg_to_rad(PITCH_LIMITS.y))
		camera.rotation.x = pitch

	if event.is_action_pressed("pause"):
		if Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
			Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
		else:
			Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
			
	if event.is_action_pressed("swap"):
		if CAM_OFFSET.x > 0.0:
			CAM_OFFSET.x = -0.5
		else:
			CAM_OFFSET.x = 0.5

func tween_cam_offset():
	var tween: Tween = get_tree().create_tween()
	tween.set_parallel(true)
	tween.tween_property(camera_hori_offset,"spring_length",CAM_OFFSET.x,0.5)
	tween.tween_property(camera_vert_offset,"spring_length",CAM_OFFSET.y,0.5)
	tween.tween_property(camera_arm,"spring_length",CAM_OFFSET.z,0.5)
