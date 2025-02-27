extends RigidBody2D

@export var MAX_SPEED: float = 100.0
var direction: Vector2 = Vector2.ZERO
var DELTA: float = 0.0
var toggle: bool = false
# Called when the node enters the scene tree for the first time.
func _ready():
	pass


func _process(delta):
	print("Sleeping: ", sleeping)

func _integrate_forces(state):
	direction = Input.get_vector("left", "right","up","down")
	if toggle:
		if not direction.is_zero_approx():
			state.linear_velocity = direction * MAX_SPEED
		else:
			state.linear_velocity.move_toward(Vector2.ZERO,self.linear_damp * state.step)
	else:
		self.apply_central_force(Vector2.LEFT*10000*state.step)
	

func _input(event):
	if Input.is_action_just_pressed("toggle"):
		sleeping = false
		if not toggle:
			toggle = true
			can_sleep = false
		else: 
			toggle = false
			can_sleep = true 
		print("Toggle: ",toggle)
