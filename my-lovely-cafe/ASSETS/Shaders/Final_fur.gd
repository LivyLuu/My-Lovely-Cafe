@tool
extends MeshInstance3D
class_name FinalFur
# Attach this directly to the MeshInstance3D you want fur on.
# It automatically builds and chains N shell materials via Next Pass —
# no manual duplicating/chaining needed. Rebuilds live in the editor
# whenever you change a value below.

@export var fur_shader: Shader

@export_range(1, 16, 1, "or_greater") var shell_count: int = 6:
	set(value):
		shell_count = value
		_rebuild_shells()

@export_range(0.0, 0.3, 0.001, "or_greater") var total_thickness: float = 0.03:
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

@export var pattern_tiling: Vector2 = Vector2(4.0, 4.0):
	set(value):
		pattern_tiling = value
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

@export var sheen_color: Color = Color(1.0, 1.0, 1.0):
	set(value):
		sheen_color = value
		_rebuild_shells()

@export_range(0.0, 2.0) var sheen_strength: float = 0.4:
	set(value):
		sheen_strength = value
		_rebuild_shells()

@export_range(1.0, 32.0) var sheen_power: float = 12.0:
	set(value):
		sheen_power = value
		_rebuild_shells()

@export var rim_enabled: bool = true:
	set(value):
		rim_enabled = value
		_rebuild_shells()

@export var rim_color: Color = Color(1.0, 0.9, 0.75):
	set(value):
		rim_color = value
		_rebuild_shells()

@export_range(1.0, 8.0) var rim_power: float = 3.0:
	set(value):
		rim_power = value
		_rebuild_shells()

@export_range(0.0, 3.0) var rim_strength: float = 0.5:
	set(value):
		rim_strength = value
		_rebuild_shells()

func _ready() -> void:
	_rebuild_shells()

func _rebuild_shells() -> void:
	if fur_shader == null:
		return

	# Base material is whatever "skin" material is on the mesh. If none
	# exists, auto-create one — using the pattern texture's actual look
	# if you've assigned one, otherwise falling back to a flat root_color
	# exactly like before.
	var base_material: Material = get_surface_override_material(0)
	if base_material == null:
		var fallback := StandardMaterial3D.new()
		if pattern_texture != null:
			fallback.albedo_texture = pattern_texture
			fallback.uv1_scale = Vector3(pattern_tiling.x, pattern_tiling.y, 1.0)
			fallback.albedo_color = Color.WHITE
		else:
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
		shell_material.set_shader_parameter("pattern_tiling", pattern_tiling)
		shell_material.set_shader_parameter("pattern_strength", pattern_strength)
		shell_material.set_shader_parameter("fur_pattern", fur_pattern)
		shell_material.set_shader_parameter("fur_tiling", fur_tiling)
		shell_material.set_shader_parameter("fur_density", fur_density)
		shell_material.set_shader_parameter("fur_lean", fur_lean)
		shell_material.set_shader_parameter("sheen_color", sheen_color)
		shell_material.set_shader_parameter("sheen_strength", sheen_strength)
		shell_material.set_shader_parameter("sheen_power", sheen_power)
		shell_material.set_shader_parameter("rim_enabled", rim_enabled)
		shell_material.set_shader_parameter("rim_color", rim_color)
		shell_material.set_shader_parameter("rim_power", rim_power)
		shell_material.set_shader_parameter("rim_strength", rim_strength)

		previous.next_pass = shell_material
		previous = shell_material

	previous.next_pass = null  # make sure the chain ends cleanly
	
