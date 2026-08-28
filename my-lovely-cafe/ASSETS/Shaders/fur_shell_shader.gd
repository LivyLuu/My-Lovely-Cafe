@tool
extends MeshInstance3D
class_name FurShellGenerator
# Attach this directly to the MeshInstance3D you want fur on.
# It automatically builds and chains N shell materials via Next Pass —
# no manual duplicating/chaining needed. Rebuilds live in the editor
# whenever you change a value below.

@export var fur_shader: Shader

@export_range(1, 16, 1, "or_greater") var shell_count: int = 6:
	set(value):
		shell_count = value
		_rebuild_shells()

@export_range(0.0, 0.1, 0.001, "or_greater") var total_thickness: float = 0.03:
	set(value):
		total_thickness = value
		_rebuild_shells()

@export var root_color: Color = Color(0.35, 0.25, 0.18):
	set(value):
		root_color = value
		_rebuild_shells()

@export var tip_color: Color = Color(0.6, 0.5, 0.42):
	set(value):
		tip_color = value
		_rebuild_shells()

@export var pattern_texture: Texture2D:
	set(value):
		pattern_texture = value
		_rebuild_shells()

@export_range(0.0, 1.0) var pattern_strength: float = 0.6:
	set(value):
		pattern_strength = value
		_rebuild_shells()

@export var fur_pattern: Texture2D:
	set(value):
		fur_pattern = value
		_rebuild_shells()

@export var fur_tiling: Vector2 = Vector2(12.0, 12.0):
	set(value):
		fur_tiling = value
		_rebuild_shells()

@export_range(0.0, 1.0) var fur_density: float = 0.55:
	set(value):
		fur_density = value
		_rebuild_shells()

@export var fur_lean: Vector3 = Vector3(0.2, -0.4, 0.0):
	set(value):
		fur_lean = value
		_rebuild_shells()

@export_range(0.0, 2.0) var sheen_strength: float = 0.4:
	set(value):
		sheen_strength = value
		_rebuild_shells()

@export_range(1.0, 32.0) var sheen_power: float = 12.0:
	set(value):
		sheen_power = value
		_rebuild_shells()

func _ready() -> void:
	_rebuild_shells()

func _rebuild_shells() -> void:
	if fur_shader == null:
		return

	# Base material is whatever "skin" material is already on the mesh.
	# If none exists yet, create a simple fallback so the chain has
	# somewhere to attach.
	var base_material: Material = get_surface_override_material(0)
	if base_material == null:
		var fallback := StandardMaterial3D.new()
		fallback.albedo_color = root_color
		set_surface_override_material(0, fallback)
		base_material = fallback

	var previous: Material = base_material

	for i in range(1, shell_count + 1):
		var shell_index: float = float(i) / float(shell_count)
		var shell_material := ShaderMaterial.new()
		shell_material.shader = fur_shader
		shell_material.set_shader_parameter("shell_index", shell_index)
		shell_material.set_shader_parameter("fur_thickness", total_thickness)
		shell_material.set_shader_parameter("root_color", root_color)
		shell_material.set_shader_parameter("tip_color", tip_color)
		shell_material.set_shader_parameter("pattern_texture", pattern_texture)
		shell_material.set_shader_parameter("pattern_strength", pattern_strength)
		shell_material.set_shader_parameter("fur_pattern", fur_pattern)
		shell_material.set_shader_parameter("fur_tiling", fur_tiling)
		shell_material.set_shader_parameter("fur_density", fur_density)
		shell_material.set_shader_parameter("fur_lean", fur_lean)
		shell_material.set_shader_parameter("sheen_strength", sheen_strength)
		shell_material.set_shader_parameter("sheen_power", sheen_power)

		previous.next_pass = shell_material
		previous = shell_material

	previous.next_pass = null  # make sure the chain ends cleanly
