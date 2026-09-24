@tool
extends Node3D
class_name RainController

## Multiplier for fall speed. 1.0 = the rain's original tuned speed.
## Higher values fall faster and stretch into longer streaks;
## lower values fall slower and shrink into shorter droplets.
@export_range(0.1, 3.0, 0.05) var rain_speed: float = 1.0:
	set(value):
		rain_speed = value
		_apply_speed()

const BASE_VELOCITY_MIN := 4.0
const BASE_VELOCITY_MAX := 6.0
const BASE_GRAVITY_Y := -9.8


func _ready() -> void:
	_apply_speed()


func _apply_speed() -> void:
	if not is_node_ready():
		return

	var rain_fall := get_node_or_null("RainFall") as GPUParticles3D
	if not rain_fall:
		return

	var process_mat := rain_fall.process_material as ParticleProcessMaterial
	if process_mat:
		process_mat.initial_velocity_min = BASE_VELOCITY_MIN * rain_speed
		process_mat.initial_velocity_max = BASE_VELOCITY_MAX * rain_speed
		process_mat.gravity = Vector3(0.0, BASE_GRAVITY_Y * rain_speed, 0.0)

	var mesh := rain_fall.draw_pass_1 as PrimitiveMesh
	if mesh and mesh.material is ShaderMaterial:
		(mesh.material as ShaderMaterial).set_shader_parameter("streak_length", rain_speed)
