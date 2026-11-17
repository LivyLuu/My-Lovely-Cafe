@tool
extends MeshInstance3D
class_name FinalFur
## Soft, Quest-friendly shell fur for ONE surface of this MeshInstance3D (surface 0 = the cat's body).
##
## This node's own mesh and materials are never touched. The script builds hidden child
## MultiMeshInstance3D nodes that draw a copy of just the fur surface once per layer using
## ASSETS/Shaders/fur_quest.gdshader, so a whole coat is ONE draw call. Those children are
## internal and have no owner, so they are never saved into your scenes. Up close you get all
## the layers; farther away a cheaper copy with half the layers takes over (see Quest / Performance).

const FUR_SHADER := preload("res://ASSETS/Shaders/fur_quest.gdshader")
const BASE_HIDER_SHADER := preload("res://ASSETS/Shaders/fur_base_hider.gdshader")
const MAX_LAYERS := 24
# Wrap-lighting amount at which the fur's brightness matches a default StandardMaterial3D
# (measured against the cat's body material from several angles; within a few percent).
const BASE_MATCH_SOFTNESS := 0.07
const NEAR_NODE := "FurShells"
const FAR_NODE := "FurShellsFar"

@export_tool_button("Rebuild Fur") var rebuild_fur: Callable = _rebuild
## Copies the fur settings in use into a NEW preset file (saved beside the current preset, named by you)
## and switches this cat to it, so you can change this cat's fur without touching any other cat.
@export_tool_button("New Fur Variant", "Duplicate") var new_variant: Callable = _on_new_variant

## A reusable fur preset, for example "white long fur". When one is assigned it supplies every fur
## setting (except Surface Index), and this node's own sliders below are hidden. Edit the preset
## itself to change the look everywhere it is used. Leave empty to use the sliders below.
@export var fur_look: FurLook:
	set(value):
		if fur_look != null and fur_look.changed.is_connected(_queue_rebuild):
			fur_look.changed.disconnect(_queue_rebuild)
		fur_look = value
		if fur_look != null:
			fur_look.changed.connect(_queue_rebuild)
		notify_property_list_changed()
		_queue_rebuild()

@export_group("Fur")
## Which surface of the mesh gets fur. 0 = the first surface (the cat's body).
@export var surface_index: int = 0:
	set(value):
		surface_index = maxi(value, 0)
		_queue_rebuild()
## Every layer is another pass of fill-rate on the GPU. 8-12 looks soft on Quest, 16+ is for PC.
@export_range(1, MAX_LAYERS, 1) var fur_layers: int = 10:
	set(value):
		fur_layers = clampi(value, 1, MAX_LAYERS)
		_queue_rebuild()
## Fur length as a fraction of the body's longest side, so it looks the same at any model scale.
@export_range(0.0, 0.15, 0.001) var fur_length: float = 0.03:
	set(value):
		fur_length = value
		_queue_rebuild()
## How much the fur droops toward the ground (in world space) near the tips.
@export_range(0.0, 1.0, 0.01) var gravity: float = 0.3:
	set(value):
		gravity = value
		_queue_rebuild()
## Extra sweep of the fur in the mesh's own space, e.g. toward the tail. Its length is the strength.
@export var comb_direction: Vector3 = Vector3.ZERO:
	set(value):
		comb_direction = value
		_queue_rebuild()

@export_group("Strands")
## Hairs per UV unit. Higher = finer fur. Hairs smaller than a pixel fade smoothly instead of shimmering.
@export_range(40.0, 600.0, 1.0) var strand_density: float = 260.0:
	set(value):
		strand_density = value
		_queue_rebuild()
## How thick the hairs are at the root. Higher = denser, less skin showing through.
@export_range(0.0, 1.0, 0.01) var fur_density: float = 0.825:
	set(value):
		fur_density = value
		_queue_rebuild()
## Shortest hair as a fraction of the longest. Lower = more variation and wispier tips.
@export_range(0.0, 0.95, 0.01) var min_strand_height: float = 0.55:
	set(value):
		min_strand_height = value
		_queue_rebuild()
## How much the hairs gather into tufts toward their tips.
@export_range(0.0, 1.0, 0.01) var clumping: float = 0.35:
	set(value):
		clumping = value
		_queue_rebuild()
## Size of a tuft, in hairs.
@export_range(3.0, 24.0, 0.5) var clump_size: float = 8.0:
	set(value):
		clump_size = value
		_queue_rebuild()
## How much the very tips fade out. Higher = softer, wispier edges.
@export_range(0.0, 1.0, 0.01) var tip_softness: float = 0.75:
	set(value):
		tip_softness = value
		_queue_rebuild()
## Fades the layers where the surface is seen edge-on, so the outline stays soft instead of ribbed.
@export_range(0.0, 1.0, 0.01) var silhouette_softness: float = 0.65:
	set(value):
		silhouette_softness = value
		_queue_rebuild()

## How visible the individual hairs are. Lower fades them out and leaves a smooth, plush surface
## (the look of very fluffy fur). 1 = fully visible hairs.
@export_range(0.0, 1.0, 0.01) var strand_detail: float = 1.0:
	set(value):
		strand_detail = value
		_queue_rebuild()

@export_group("Fluff")
## How much the coat bulges into big soft cotton-like clumps. 0 = an even coat of hairs.
## Higher makes the outline lumpy and the surface cloudy. Works best with a longer fur length.
@export_range(0.0, 1.0, 0.01) var fluff_amount: float = 0.0:
	set(value):
		fluff_amount = value
		_queue_rebuild()
## Size of one fluff clump, as a fraction of the body's longest side.
@export_range(0.02, 0.5, 0.005) var fluff_size: float = 0.12:
	set(value):
		fluff_size = value
		_queue_rebuild()
## Bump mapping: how strongly the fluff clumps catch light and shade as little bumps.
## Only has an effect while Fluff Amount is above 0.
@export_range(0.0, 1.0, 0.01) var bump_strength: float = 0.0:
	set(value):
		bump_strength = value
		_queue_rebuild()

@export_group("Color")
## On = reuse the albedo texture and color of the material on this surface.
## Off = ignore them and color the coat with Fur Tint alone (for a plain white coat, say).
@export var use_surface_texture: bool = true:
	set(value):
		use_surface_texture = value
		_queue_rebuild()
## Overrides the surface texture when set.
@export var pattern_texture: Texture2D:
	set(value):
		pattern_texture = value
		_queue_rebuild()
## Only used when Pattern Texture is set. Otherwise the surface material's UV scale is used.
@export var pattern_tiling: Vector2 = Vector2(4.0, 4.0):
	set(value):
		pattern_tiling = value
		_queue_rebuild()
## Extra surfaces (separate materials in Blender) that grow fur too, each with its own length.
## Key = the surface's name (its material name, e.g. "Chest Fur"), value = length multiplier:
## 1.5 = 50% longer, 0.5 = half as long. Leave a surface out for no fur on it. Add the main fur
## surface's name here too if you want to scale it. Everything still draws as ONE fur mesh.
@export var region_lengths: Dictionary = {}:
	set(value):
		region_lengths = value
		_queue_rebuild()
## Optional black-and-white image painted on the model's UV layout that controls where the fur grows.
## White = the full fur set above, grey = shorter fur, black = no fur at all.
@export var height_map: Texture2D:
	set(value):
		height_map = value
		_queue_rebuild()
@export var fur_tint: Color = Color.WHITE:
	set(value):
		fur_tint = value
		_queue_rebuild()
## How closely the fur is lit like the surface underneath, so strands and skin read as one.
## 1 = identical lighting and brightness. 0 = the full softer, deeper fur shading from the sliders below.
@export_range(0.0, 1.0, 0.01) var match_base: float = 0.85:
	set(value):
		match_base = value
		_queue_rebuild()
## Color of the shadowed depths near the roots (white = no tint). Pink or lilac gives soft, warm
## shadows instead of grey ones.
@export var root_tint: Color = Color.WHITE:
	set(value):
		root_tint = value
		_queue_rebuild()
## Brightness at the root. Darker roots are what give the coat its depth.
@export_range(0.0, 1.0, 0.01) var root_shade: float = 0.72:
	set(value):
		root_shade = value
		_queue_rebuild()
@export_range(0.5, 1.5, 0.01) var tip_shade: float = 1.0:
	set(value):
		tip_shade = value
		_queue_rebuild()
## Random brightness difference between individual hairs.
@export_range(0.0, 1.0, 0.01) var strand_variation: float = 0.15:
	set(value):
		strand_variation = value
		_queue_rebuild()
## How far light wraps around the form. Higher = softer, fluffier shading.
@export_range(0.0, 1.0, 0.01) var softness: float = 0.8:
	set(value):
		softness = value
		_queue_rebuild()
@export var rim_color: Color = Color(1.0, 0.95, 0.85):
	set(value):
		rim_color = value
		_queue_rebuild()
@export_range(0.0, 1.0, 0.01) var rim_strength: float = 0.25:
	set(value):
		rim_strength = value
		_queue_rebuild()

@export_group("Smoothing")
## Shades the fur as one smooth surface: points where polygons meet share one averaged normal, so the
## model's polygon edges and flat patches don't show through the coat. The fur still grows along the
## model's real surface, so its shape doesn't change. 0 = the model's own shading. Computed once
## when the fur is built: free while playing.
@export_range(0.0, 1.0, 0.01) var smooth_normals: float = 0.0:
	set(value):
		smooth_normals = value
		_queue_rebuild()

@export_group("Base Mesh")
## On = the model's own surface (the skin under the fur) is never drawn, so it can't show through
## transparent fur, and the fur's edge fades out softly instead of ending on a hard-edged core.
## Your material is not changed or saved. It still blocks the view of whatever is behind the model.
## Off = the base surface is drawn normally underneath the fur.
@export var hide_base_mesh: bool = false:
	set(value):
		hide_base_mesh = value
		_queue_rebuild()
## How deep the fur stays fully opaque, from the roots up (as a fraction of the coat's height).
## The inner layers cover the surface completely, so you can't see through to the model, and only
## the outer layers stay wispy and transparent. 0 = every layer is see-through (the old look).
@export_range(0.0, 0.9, 0.01) var solid_core: float = 0.0:
	set(value):
		solid_core = value
		_queue_rebuild()

@export_group("Quest / Performance")
## Beyond this distance (meters) a cheaper coat with half the layers is used. 0 = always use all layers.
## Distance ranges are not applied inside the editor, so you can always see the full fur while working.
@export_range(0.0, 20.0, 0.5, "or_greater") var lod_distance: float = 2.5:
	set(value):
		lod_distance = value
		_queue_rebuild()
## Beyond this distance (meters) the fur is skipped entirely. 0 = never skip.
@export_range(0.0, 30.0, 0.5, "or_greater") var fade_distance: float = 6.0:
	set(value):
		fade_distance = value
		_queue_rebuild()

var _pending := false
var _built := false
var _base_hider: ShaderMaterial
var _base_hidden_now := false
var _watched_material: Material
var _watched_mesh: Mesh


func _ready() -> void:
	# Editor only: Godot silently re-applies a surface's real material whenever it is edited, which
	# would un-hide the base. Watch for that so the hide survives changing the material by hand.
	set_process(Engine.is_editor_hint())
	_rebuild()


func _process(_delta: float) -> void:
	_check_base_material_changed()


func _check_base_material_changed() -> void:
	if not _base_hidden_now or mesh == null or surface_index >= mesh.get_surface_count():
		return
	if get_surface_override_material(surface_index) != _watched_material or mesh != _watched_mesh:
		_apply_base_visibility(true)


func _enter_tree() -> void:
	# Re-entering the tree (after a reparent) gives back the instance's own material state, so redo ours.
	if is_node_ready():
		_queue_rebuild()


func _exit_tree() -> void:
	_apply_base_visibility(false)


# The editor refreshes the Inspector after it hot-reloads this script, which is the one
# moment a fresh script instance would otherwise leave stale fur on screen. Rebuild then.
func _validate_property(property: Dictionary) -> void:
	if Engine.is_editor_hint() and not _built:
		_queue_rebuild()
	# A Fur Look replaces this node's own fur settings, so hide the sliders that are now ignored.
	if fur_look != null and property.name in FurLook.SETTING_NAMES:
		property.usage &= ~PROPERTY_USAGE_EDITOR


func _queue_rebuild() -> void:
	if _pending or not is_node_ready():
		return
	_pending = true
	_rebuild.call_deferred()


func _rebuild() -> void:
	_pending = false
	if not is_inside_tree():
		return
	if mesh == null or surface_index >= mesh.get_surface_count():
		_remove_fur_node(NEAR_NODE)
		_remove_fur_node(FAR_NODE)
		_apply_base_visibility(false)
		return
	_built = true

	_clear_legacy_shell_chain()

	# A Fur Look, when assigned, supplies every fur setting. Otherwise this node's own settings are used.
	var s = fur_look if fur_look != null else self
	var layer_count: int = s.fur_layers
	var lod_dist: float = s.lod_distance
	var fade_dist: float = s.fade_distance
	var regions: Dictionary = s.region_lengths
	var bounds := AABB()

	# Copy only the fur surfaces (positions, normals, UVs, indices) into ONE mesh, so the whole coat is
	# still a single draw call even when chest / ear / cheek surfaces have their own length. The first
	# custom vertex attribute carries, as full floats (so every renderer reads exactly the same numbers;
	# vertex colour is converted differently by the Compatibility renderer that Quest uses): xyz = the
	# smoothed normal for lighting, w = that surface's length multiplier.
	var surfaces := _fur_surfaces(regions)
	var verts := PackedVector3Array()
	var normals := PackedVector3Array()
	var uvs := PackedVector2Array()
	var indices := PackedInt32Array()
	var region_len := PackedFloat32Array()
	for entry in surfaces:
		var arrays := mesh.surface_get_arrays(entry[0])
		# Rigged cat: bake the mesh into the skeleton's rest pose, the shape the skinned mesh is drawn in.
		_skin_to_rest_pose(arrays)
		var sv: PackedVector3Array = arrays[Mesh.ARRAY_VERTEX]
		var sn: PackedVector3Array = arrays[Mesh.ARRAY_NORMAL]
		var suv = arrays[Mesh.ARRAY_TEX_UV]
		var si = arrays[Mesh.ARRAY_INDEX]
		var offset := verts.size()
		verts.append_array(sv)
		normals.append_array(sn)
		if suv == null or suv.size() != sv.size():
			var blank := PackedVector2Array()
			blank.resize(sv.size())
			uvs.append_array(blank)
		else:
			uvs.append_array(suv)
		if si == null or si.is_empty():
			for i in sv.size():
				indices.append(offset + i)
		else:
			for i in si:
				indices.append(offset + i)
		for i in sv.size():
			region_len.append(entry[1])
	for i in verts.size():
		bounds = AABB(verts[i], Vector3.ZERO) if i == 0 else bounds.expand(verts[i])
	var body_size := bounds.get_longest_axis_size()

	var welded := _weld(verts, normals, region_len, body_size, surfaces)
	var custom := PackedFloat32Array()
	custom.resize(verts.size() * 4)
	var use_smooth := float(s.smooth_normals) > 0.0
	for i in verts.size():
		var n: Vector3 = welded[0][i] if use_smooth else normals[i]
		custom[i * 4] = n.x
		custom[i * 4 + 1] = n.y
		custom[i * 4 + 2] = n.z
		custom[i * 4 + 3] = welded[1][i]
	var fur_arrays := []
	fur_arrays.resize(Mesh.ARRAY_MAX)
	fur_arrays[Mesh.ARRAY_VERTEX] = verts
	fur_arrays[Mesh.ARRAY_NORMAL] = normals
	fur_arrays[Mesh.ARRAY_TEX_UV] = uvs
	fur_arrays[Mesh.ARRAY_INDEX] = indices
	fur_arrays[Mesh.ARRAY_CUSTOM0] = custom
	var fur_mesh := ArrayMesh.new()
	fur_mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, fur_arrays, [], {},
			Mesh.ARRAY_CUSTOM_RGBA_FLOAT << Mesh.ARRAY_FORMAT_CUSTOM0_SHIFT)

	# Fur length is "% of body size", converted to this mesh's own local units.
	var length_local: float = s.fur_length * body_size
	var longest := 1.0
	for entry in surfaces:
		longest = maxf(longest, entry[1])
	var fur_bounds := bounds.grow(length_local * longest * (1.0 + 0.6 * float(s.fluff_amount))) # fluff lumps stick out further
	var material := _make_material(s, length_local, body_size)
	_apply_base_visibility(s.hide_base_mesh)

	# Distance ranges only apply in the game, never in the editor viewport.
	var use_lod := false
	var near_end := 0.0
	if not Engine.is_editor_hint():
		use_lod = lod_dist > 0.0 and layer_count >= 4 and (fade_dist <= 0.0 or lod_dist < fade_dist)
		near_end = lod_dist if use_lod else fade_dist
	_setup_fur_node(NEAR_NODE, fur_mesh, material, layer_count, fur_bounds, 0.0, near_end)
	if use_lod:
		var far_layers := maxi(roundi(layer_count * 0.5), 2)
		_setup_fur_node(FAR_NODE, fur_mesh, material, far_layers, fur_bounds, lod_dist, fade_dist)
	else:
		_remove_fur_node(FAR_NODE)


# Smooth shading: every vertex that sits at the same point on the mesh (polygon corners, UV seams,
# hard edges) gets the same averaged normal, so the lighting flows across the whole surface instead
# of showing polygon facets. Runs once per rebuild and the result is cached, so it costs nothing
# while the game is running. The blend with the original normals happens on the GPU.
static var _smooth_cache := {}

# Returns [welded normals, welded length multipliers]. Length multipliers are welded too, so a
# long-fur region and the body next to it agree at their shared edge (no crack in the coat): where
# surfaces meet, the multiplier that differs most from 1 wins, and the body triangles beside the
# region carry the blend back down to normal length.
func _weld(verts: PackedVector3Array, normals: PackedVector3Array, region_len: PackedFloat32Array,
		body_size: float, surfaces: Array) -> Array:
	var cache_key := "%d:%s:%d" % [mesh.get_instance_id(), str(surfaces), verts.size()]
	if _smooth_cache.size() > 8:
		_smooth_cache.clear()
	if _smooth_cache.has(cache_key):
		return _smooth_cache[cache_key]
	var inv_cell := 1.0 / maxf(body_size * 0.0001, 0.0000001)
	var sums := {}
	var lens := {}
	for i in verts.size():
		var key := Vector3i((verts[i] * inv_cell).round())
		sums[key] = sums.get(key, Vector3.ZERO) + normals[i]
		if not lens.has(key) or absf(region_len[i] - 1.0) > absf(float(lens[key]) - 1.0):
			lens[key] = region_len[i]
	var welded := PackedVector3Array()
	var welded_len := PackedFloat32Array()
	welded.resize(verts.size())
	welded_len.resize(verts.size())
	for i in verts.size():
		var key := Vector3i((verts[i] * inv_cell).round())
		var summed: Vector3 = sums[key]
		welded[i] = summed.normalized() if summed.length_squared() > 0.0000001 else normals[i]
		welded_len[i] = lens[key]
	var result := [welded, welded_len]
	_smooth_cache[cache_key] = result
	return result


# Which surfaces grow fur, as [surface, length multiplier] pairs. The main one (Surface Index) always
# does; any other surface grows fur when its name (the material name in Blender) is listed in the
# Region Lengths setting with a multiplier above 0.
func _fur_surfaces(regions: Dictionary) -> Array:
	var out := []
	if mesh == null:
		return out
	for i in mesh.get_surface_count():
		var surface_name: String = (mesh as ArrayMesh).surface_get_name(i) if mesh is ArrayMesh else ""
		if i == surface_index:
			out.append([i, maxf(float(regions.get(surface_name, 1.0)), 0.0)])
		elif regions.has(surface_name) and float(regions[surface_name]) > 0.0:
			out.append([i, float(regions[surface_name])])
	return out


# Hides (or shows again) the base surface by swapping the material the RENDERER uses for it. The
# node's own surface material is never touched, so nothing is saved into your scenes. Every
# surface is re-applied from the node's real materials first, which also cleans up after a
# script reload or a change of Surface Index.
func _apply_base_visibility(hidden: bool) -> void:
	_base_hidden_now = false
	var instance := get_instance()
	if not instance.is_valid() or mesh == null:
		return
	for i in mesh.get_surface_count():
		var real := get_surface_override_material(i)
		RenderingServer.instance_set_surface_override_material(instance, i, real.get_rid() if real else RID())
	if not hidden or surface_index >= mesh.get_surface_count():
		return
	if _base_hider == null:
		_base_hider = ShaderMaterial.new()
		_base_hider.shader = BASE_HIDER_SHADER
		_base_hider.render_priority = -100 # draws before the fur layers, so they test against its depth
	var active = fur_look if fur_look != null else self
	for entry in _fur_surfaces(active.region_lengths): # every surface that grows fur is hidden, not just the main one
		RenderingServer.instance_set_surface_override_material(instance, entry[0], _base_hider.get_rid())
	_base_hidden_now = true
	_watched_material = get_surface_override_material(surface_index)
	_watched_mesh = mesh


# `s` is either this node or an assigned FurLook: both have the same fur settings.
func _make_material(s, length_local: float, body_size: float) -> ShaderMaterial:
	var texture: Texture2D = s.pattern_texture
	var tiling: Vector2 = s.pattern_tiling
	var tint: Color = s.fur_tint
	var base := get_active_material(surface_index) as BaseMaterial3D
	if texture == null and base != null and s.use_surface_texture:
		texture = base.albedo_texture
		tiling = Vector2(base.uv1_scale.x, base.uv1_scale.y)
		tint *= base.albedo_color

	var material := ShaderMaterial.new()
	material.shader = FUR_SHADER
	material.set_shader_parameter("albedo_tex", texture)
	material.set_shader_parameter("albedo_tiling", tiling)
	material.set_shader_parameter("fur_tint", tint)
	material.set_shader_parameter("height_map", s.height_map)
	material.set_shader_parameter("use_height_map", 1.0 if s.height_map != null else 0.0)
	material.set_shader_parameter("fur_length", length_local)
	material.set_shader_parameter("gravity", s.gravity)
	material.set_shader_parameter("comb", s.comb_direction)
	material.set_shader_parameter("strand_density", s.strand_density)
	material.set_shader_parameter("strand_radius", lerpf(0.15, 0.65, s.fur_density))
	material.set_shader_parameter("min_strand_height", s.min_strand_height)
	material.set_shader_parameter("tip_softness", s.tip_softness)
	material.set_shader_parameter("silhouette_softness", s.silhouette_softness)
	material.set_shader_parameter("smooth_amount", s.smooth_normals)
	material.set_shader_parameter("base_hidden", 1.0 if s.hide_base_mesh else 0.0)
	material.set_shader_parameter("core_depth", s.solid_core)
	material.set_shader_parameter("clumping", s.clumping)
	material.set_shader_parameter("clump_size", s.clump_size)
	material.set_shader_parameter("strand_detail", s.strand_detail)
	material.set_shader_parameter("fluff_amount", s.fluff_amount)
	material.set_shader_parameter("bump_strength", s.bump_strength)
	# Fluff clump size is "% of body size"; the shader wants noise cells per unit of the mesh's own space.
	material.set_shader_parameter("fluff_frequency", 1.0 / maxf(float(s.fluff_size) * body_size, 0.00001))
	# Match Base pulls every extra bit of fur shading toward a plainly lit surface.
	var match_amount: float = s.match_base
	var root_tint_color: Color = s.root_tint
	material.set_shader_parameter("root_tint", root_tint_color.lerp(Color.WHITE, match_amount))
	material.set_shader_parameter("root_shade", lerpf(s.root_shade, 1.0, match_amount))
	material.set_shader_parameter("tip_shade", lerpf(s.tip_shade, 1.0, match_amount))
	material.set_shader_parameter("strand_variation", s.strand_variation * (1.0 - match_amount))
	material.set_shader_parameter("softness", lerpf(s.softness, BASE_MATCH_SOFTNESS, match_amount))
	material.set_shader_parameter("rim_color", s.rim_color)
	material.set_shader_parameter("rim_strength", s.rim_strength * (1.0 - match_amount))
	return material


# One hidden MultiMeshInstance3D = one draw call. Each instance is one fur layer, and
# INSTANCE_CUSTOM.x tells the shader how high that layer sits (0..1).
func _setup_fur_node(node_name: String, fur_mesh: ArrayMesh, material: ShaderMaterial,
		layer_count: int, fur_bounds: AABB, range_begin: float, range_end: float) -> void:
	var fur := get_node_or_null(node_name) as MultiMeshInstance3D
	if fur == null:
		fur = MultiMeshInstance3D.new()
		fur.name = node_name
		add_child(fur, false, Node.INTERNAL_MODE_BACK)

	var multimesh := MultiMesh.new()
	multimesh.transform_format = MultiMesh.TRANSFORM_3D
	multimesh.use_custom_data = true
	multimesh.mesh = fur_mesh
	multimesh.instance_count = layer_count
	for i in layer_count:
		multimesh.set_instance_transform(i, Transform3D.IDENTITY)
		# x = layer height (0..1), y = 1 on the innermost layer (the solid undercoat)
		multimesh.set_instance_custom_data(i, Color((i + 1.0) / (layer_count + 1.0), 1.0 if i == 0 else 0.0, 0.0, 0.0))
	multimesh.custom_aabb = fur_bounds
	fur.multimesh = multimesh

	fur.material_override = material
	fur.transform = _skinned_offset()
	fur.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	fur.layers = layers
	# Ranges are exactly adjacent (near ends where far begins) and use no hysteresis margin. A margin
	# would leave a dead band around the boundary where a freshly spawned cat shows no fur at all.
	fur.visibility_range_begin = range_begin
	fur.visibility_range_begin_margin = 0.0
	fur.visibility_range_end = range_end
	fur.visibility_range_end_margin = 0.0


func _remove_fur_node(node_name: String) -> void:
	var fur := get_node_or_null(node_name)
	if fur:
		fur.queue_free()


# Older versions of this script chained blank/old "shell" ShaderMaterials onto the surface
# material via next_pass, and those got saved into the scene. Remove them if present.
func _clear_legacy_shell_chain() -> void:
	var base := get_surface_override_material(surface_index)
	if base == null:
		return
	var pass_material := base.next_pass as ShaderMaterial
	if pass_material == null:
		return
	var legacy := pass_material.shader == null \
			or pass_material.shader.code.strip_edges().is_empty() \
			or pass_material.shader.code.contains("shell_index")
	if legacy:
		base.next_pass = null


# A rigged (skinned) mesh is drawn in its Skeleton3D's space, ignoring its own node transform, but the
# fur is a plain child of this node, so it would inherit that ignored transform and end up rotated or
# scaled differently from the cat (the importer often gives the mesh node a 100x / 90 degree transform).
# This returns the offset that puts the fur where the skinned mesh is actually drawn. The fur is
# placed for the skeleton's rest pose, so it does not bend with animation.
func _skinned_offset() -> Transform3D:
	var rig := get_node_or_null(skeleton) as Skeleton3D
	if rig == null or get_skin() == null or not is_inside_tree() or not rig.is_inside_tree():
		return Transform3D.IDENTITY
	return global_transform.affine_inverse() * rig.global_transform


# Moves the fur surface's vertices and normals from the mesh's own space into the skeleton's space,
# using the rest pose and the mesh's skin (the same bone maths the GPU does for the real cat).
# Returns false, and changes nothing, for a mesh that is not rigged.
func _skin_to_rest_pose(arrays: Array) -> bool:
	var rig := get_node_or_null(skeleton) as Skeleton3D
	var rig_skin := get_skin()
	if rig == null or rig_skin == null:
		return false
	var bones = arrays[Mesh.ARRAY_BONES]
	var weights = arrays[Mesh.ARRAY_WEIGHTS]
	var verts: PackedVector3Array = arrays[Mesh.ARRAY_VERTEX]
	var normals: PackedVector3Array = arrays[Mesh.ARRAY_NORMAL]
	if bones == null or weights == null or verts.is_empty() or normals.size() != verts.size():
		return false
	var per_vertex: int = bones.size() / verts.size()
	if per_vertex < 1 or weights.size() != bones.size():
		return false
	var skin_xf: Array[Transform3D] = []
	for i in rig_skin.get_bind_count():
		var bone := rig_skin.get_bind_bone(i)
		if bone < 0:
			bone = rig.find_bone(rig_skin.get_bind_name(i))
		skin_xf.append(rig.get_bone_global_rest(bone) * rig_skin.get_bind_pose(i) if bone >= 0 else Transform3D.IDENTITY)
	var out_verts := PackedVector3Array()
	var out_normals := PackedVector3Array()
	out_verts.resize(verts.size())
	out_normals.resize(verts.size())
	for v in verts.size():
		var p := Vector3.ZERO
		var n := Vector3.ZERO
		var total := 0.0
		for k in per_vertex:
			var w: float = weights[v * per_vertex + k]
			if w <= 0.0:
				continue
			var xf: Transform3D = skin_xf[bones[v * per_vertex + k]]
			p += (xf * verts[v]) * w
			n += (xf.basis * normals[v]) * w
			total += w
		if total <= 0.0:
			out_verts[v] = verts[v]
			out_normals[v] = normals[v]
		else:
			out_verts[v] = p / total
			out_normals[v] = n.normalized()
	arrays[Mesh.ARRAY_VERTEX] = out_verts
	arrays[Mesh.ARRAY_NORMAL] = out_normals
	arrays[Mesh.ARRAY_BONES] = null
	arrays[Mesh.ARRAY_WEIGHTS] = null
	return true


# Editor button: duplicate the fur settings this node is using into a new FurLook file and assign it.
func _on_new_variant() -> void:
	var source: FurLook = fur_look
	var folder := ""
	var suggested := name
	if source != null and not source.resource_path.is_empty():
		folder = source.resource_path.get_base_dir()
		suggested = source.resource_path.get_file().get_basename()
	else:
		# No preset yet: turn this node's own sliders into one.
		source = FurLook.new()
		for setting in FurLook.SETTING_NAMES:
			source.set(setting, get(setting))
		var styles := "res://ASSETS/3D/Cats/Fur Styles"
		folder = styles if DirAccess.dir_exists_absolute(styles) else (owner.scene_file_path.get_base_dir() if owner and not owner.scene_file_path.is_empty() else "res://")
	FurLook.ask_for_variant(source, folder, suggested, func(copy: FurLook) -> void:
		fur_look = copy
		var editor = Engine.get_singleton("EditorInterface")
		editor.mark_scene_as_unsaved()
		editor.edit_node(self))
