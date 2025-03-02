@tool
extends WorldEnvironment
class_name EnvironmentManager

@export var player_refrence:Node3D:
	set(ref):
		player_refrence = ref
		if wind:
			wind.follow_target = ref

@export_category("Wind")
@export var wind_direction: Vector3 = Vector3(0.0,0.0,0.0):
	set(new_direction):
		RenderingServer.global_shader_parameter_set("wind_direction",new_direction)
		wind_direction = new_direction
		if wind and wind.process_material is ParticleProcessMaterial:
			wind.process_material.direction = new_direction
			if wind_direction.is_zero_approx() or is_zero_approx(wind_speed):
				wind.amount_ratio = 0.0
			else:
				wind.amount_ratio = 1.0

@export var wind_speed: float = 0.0:
	set(new_val):
		RenderingServer.global_shader_parameter_set("wind_speed",new_val)
		wind_speed = new_val
		if wind and wind.process_material is ParticleProcessMaterial:
			if is_zero_approx(wind_speed) or wind_direction.is_zero_approx():
				wind.amount_ratio = 0.0
			else:
				wind.amount_ratio = 1.0

@onready var wind: Wind = $Wind

func _ready():
	if is_zero_approx(wind_speed) or wind_direction.is_zero_approx():
		wind.amount_ratio = 0.0
	else:
		wind.amount_ratio = 1.0
