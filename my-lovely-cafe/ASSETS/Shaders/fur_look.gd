@tool
extends Resource
class_name FurLook
## A reusable fur preset for the FinalFur node (see ASSETS/Shaders/Final_fur.gd).
##
## Save one of these as a .tres (for example "white long fur"), then drag it into the "Fur Look"
## slot of any FinalFur node. Every setting below is then used for that fur, and editing this
## resource updates all the fur that uses it. The settings mean exactly what they do on the node.

const MAX_LAYERS := 24
# Used by FinalFur to know which of its own sliders a Fur Look replaces.
const SETTING_NAMES := ["fur_layers", "fur_length", "gravity", "comb_direction", "strand_density", "fur_density", "min_strand_height", "clumping", "clump_size", "tip_softness", "silhouette_softness", "strand_detail", "fluff_amount", "fluff_size", "bump_strength", "use_surface_texture", "pattern_texture", "pattern_tiling", "height_map", "region_lengths", "fur_tint", "match_base", "root_tint", "root_shade", "tip_shade", "strand_variation", "softness", "rim_color", "rim_strength", "smooth_normals", "hide_base_mesh", "solid_core", "lod_distance", "fade_distance"]

## Makes a copy of this preset, saved next to it under a name you pick. Edit the copy freely: this one is untouched.
@export_tool_button("New Fur Variant", "Duplicate") var new_variant_button: Callable = _on_new_variant_pressed

@export_group("Fur")
## Every layer is another pass of fill-rate on the GPU. 8-12 looks soft on Quest, 16+ is for PC.
@export_range(1, MAX_LAYERS, 1) var fur_layers: int = 10:
	set(value):
		fur_layers = clampi(value, 1, MAX_LAYERS)
		emit_changed()
## Fur length as a fraction of the body's longest side, so it looks the same at any model scale.
@export_range(0.0, 0.15, 0.001) var fur_length: float = 0.03:
	set(value):
		fur_length = value
		emit_changed()
## How much the fur droops toward the ground (in world space) near the tips.
@export_range(0.0, 1.0, 0.01) var gravity: float = 0.3:
	set(value):
		gravity = value
		emit_changed()
## Extra sweep of the fur in the mesh's own space, e.g. toward the tail. Its length is the strength.
@export var comb_direction: Vector3 = Vector3.ZERO:
	set(value):
		comb_direction = value
		emit_changed()

@export_group("Strands")
## Hairs per UV unit. Higher = finer fur. Hairs smaller than a pixel fade smoothly instead of shimmering.
@export_range(40.0, 600.0, 1.0) var strand_density: float = 260.0:
	set(value):
		strand_density = value
		emit_changed()
## How thick the hairs are at the root. Higher = denser, less skin showing through.
@export_range(0.0, 1.0, 0.01) var fur_density: float = 0.825:
	set(value):
		fur_density = value
		emit_changed()
## Shortest hair as a fraction of the longest. Lower = more variation and wispier tips.
@export_range(0.0, 0.95, 0.01) var min_strand_height: float = 0.55:
	set(value):
		min_strand_height = value
		emit_changed()
## How much the hairs gather into tufts toward their tips.
@export_range(0.0, 1.0, 0.01) var clumping: float = 0.35:
	set(value):
		clumping = value
		emit_changed()
## Size of a tuft, in hairs.
@export_range(3.0, 24.0, 0.5) var clump_size: float = 8.0:
	set(value):
		clump_size = value
		emit_changed()
## How much the very tips fade out. Higher = softer, wispier edges.
@export_range(0.0, 1.0, 0.01) var tip_softness: float = 0.75:
	set(value):
		tip_softness = value
		emit_changed()
## Fades the layers where the surface is seen edge-on, so the outline stays soft instead of ribbed.
@export_range(0.0, 1.0, 0.01) var silhouette_softness: float = 0.65:
	set(value):
		silhouette_softness = value
		emit_changed()

## How visible the individual hairs are. Lower fades them out and leaves a smooth, plush surface
## (the look of very fluffy fur). 1 = fully visible hairs.
@export_range(0.0, 1.0, 0.01) var strand_detail: float = 1.0:
	set(value):
		strand_detail = value
		emit_changed()

@export_group("Fluff")
## How much the coat bulges into big soft cotton-like clumps. 0 = an even coat of hairs.
## Higher makes the outline lumpy and the surface cloudy. Works best with a longer fur length.
@export_range(0.0, 1.0, 0.01) var fluff_amount: float = 0.0:
	set(value):
		fluff_amount = value
		emit_changed()
## Size of one fluff clump, as a fraction of the body's longest side.
@export_range(0.02, 0.5, 0.005) var fluff_size: float = 0.12:
	set(value):
		fluff_size = value
		emit_changed()
## Bump mapping: how strongly the fluff clumps catch light and shade as little bumps.
## Only has an effect while Fluff Amount is above 0.
@export_range(0.0, 1.0, 0.01) var bump_strength: float = 0.0:
	set(value):
		bump_strength = value
		emit_changed()

@export_group("Color")
## On = reuse the albedo texture and color of the material on this surface.
## Off = ignore them and color the coat with Fur Tint alone (for a plain white coat, say).
@export var use_surface_texture: bool = true:
	set(value):
		use_surface_texture = value
		emit_changed()
## Overrides the surface texture when set.
@export var pattern_texture: Texture2D:
	set(value):
		pattern_texture = value
		emit_changed()
## Only used when Pattern Texture is set. Otherwise the surface material's UV scale is used.
@export var pattern_tiling: Vector2 = Vector2(4.0, 4.0):
	set(value):
		pattern_tiling = value
		emit_changed()
## Extra surfaces (separate materials in Blender) that grow fur too, each with its own length.
## Key = the surface's name or material name (e.g. "Chest Fur") or its number (0, 1, 2... in the mesh's
## surface order; .glb files often lose names, so the number always works). Value = length multiplier:
## 1.5 = 50% longer, 0.5 = half as long. Leave a surface out for no fur on it. Add the main fur
## surface's name here too if you want to scale it. Everything still draws as ONE fur mesh.
@export var region_lengths: Dictionary = {}:
	set(value):
		region_lengths = value
		emit_changed()
## Optional black-and-white image painted on the model's UV layout that controls where the fur grows.
## White = the full fur set above, grey = shorter fur, black = no fur at all.
@export var height_map: Texture2D:
	set(value):
		height_map = value
		emit_changed()
@export var fur_tint: Color = Color.WHITE:
	set(value):
		fur_tint = value
		emit_changed()
## How closely the fur is lit like the surface underneath, so strands and skin read as one.
## 1 = identical lighting and brightness. 0 = the full softer, deeper fur shading from the sliders below.
@export_range(0.0, 1.0, 0.01) var match_base: float = 0.85:
	set(value):
		match_base = value
		emit_changed()
## Color of the shadowed depths near the roots (white = no tint). Pink or lilac gives soft, warm
## shadows instead of grey ones.
@export var root_tint: Color = Color.WHITE:
	set(value):
		root_tint = value
		emit_changed()
## Brightness at the root. Darker roots are what give the coat its depth.
@export_range(0.0, 1.0, 0.01) var root_shade: float = 0.72:
	set(value):
		root_shade = value
		emit_changed()
@export_range(0.5, 1.5, 0.01) var tip_shade: float = 1.0:
	set(value):
		tip_shade = value
		emit_changed()
## Random brightness difference between individual hairs.
@export_range(0.0, 1.0, 0.01) var strand_variation: float = 0.15:
	set(value):
		strand_variation = value
		emit_changed()
## How far light wraps around the form. Higher = softer, fluffier shading.
@export_range(0.0, 1.0, 0.01) var softness: float = 0.8:
	set(value):
		softness = value
		emit_changed()
@export var rim_color: Color = Color(1.0, 0.95, 0.85):
	set(value):
		rim_color = value
		emit_changed()
@export_range(0.0, 1.0, 0.01) var rim_strength: float = 0.25:
	set(value):
		rim_strength = value
		emit_changed()

@export_group("Smoothing")
## Shades the fur as one smooth surface: points where polygons meet share one averaged normal, so the
## model's polygon edges and flat patches don't show through the coat. The fur still grows along the
## model's real surface, so its shape doesn't change. 0 = the model's own shading. Computed once
## when the fur is built: free while playing.
@export_range(0.0, 1.0, 0.01) var smooth_normals: float = 0.0:
	set(value):
		smooth_normals = value
		emit_changed()

@export_group("Base Mesh")
## On = the model's own surface (the skin under the fur) is never drawn, so it can't show through
## transparent fur, and the fur's edge fades out softly instead of ending on a hard-edged core.
## Your material is not changed or saved. It still blocks the view of whatever is behind the model.
## Off = the base surface is drawn normally underneath the fur.
@export var hide_base_mesh: bool = false:
	set(value):
		hide_base_mesh = value
		emit_changed()
## How deep the fur stays fully opaque, from the roots up (as a fraction of the coat's height).
## The inner layers cover the surface completely, so you can't see through to the model, and only
## the outer layers stay wispy and transparent. 0 = every layer is see-through (the old look).
@export_range(0.0, 0.9, 0.01) var solid_core: float = 0.0:
	set(value):
		solid_core = value
		emit_changed()

@export_group("Quest / Performance")
## Beyond this distance (meters) a cheaper coat with half the layers is used. 0 = always use all layers.
## Distance ranges are not applied inside the editor, so you can always see the full fur while working.
@export_range(0.0, 20.0, 0.5, "or_greater") var lod_distance: float = 2.5:
	set(value):
		lod_distance = value
		emit_changed()
## Beyond this distance (meters) the fur is skipped entirely. 0 = never skip.
@export_range(0.0, 30.0, 0.5, "or_greater") var fade_distance: float = 6.0:
	set(value):
		fade_distance = value
		emit_changed()



func _on_new_variant_pressed() -> void:
	ask_for_variant(self, resource_path.get_base_dir(), resource_path.get_file().get_basename(), func(copy: FurLook) -> void:
		var editor = Engine.get_singleton("EditorInterface")
		editor.edit_resource(copy))


# Editor only. Asks for a name, saves a duplicate of `source` as "<folder>/<name>.tres" (never over an
# existing file), then calls `done` with the new FurLook. `source` is not changed.
static func ask_for_variant(source: FurLook, folder: String, suggested_name: String, done: Callable) -> void:
	if not Engine.is_editor_hint() or not Engine.has_singleton("EditorInterface"):
		return
	var editor = Engine.get_singleton("EditorInterface")
	if folder.is_empty() or not DirAccess.dir_exists_absolute(folder):
		folder = "res://"
	var dialog := ConfirmationDialog.new()
	dialog.title = "New Fur Variant"
	dialog.ok_button_text = "Create"
	var box := VBoxContainer.new()
	var label := Label.new()
	label.text = "Name for the new fur (saved in %s):" % folder
	var field := LineEdit.new()
	field.custom_minimum_size.x = 360
	field.text = _free_name(folder, suggested_name if not suggested_name.is_empty() else "New Fur")
	box.add_child(label)
	box.add_child(field)
	dialog.add_child(box)
	var accept := func() -> void:
		var clean := field.text.strip_edges().validate_filename()
		if clean.is_empty():
			clean = "New Fur"
		var path := "%s/%s.tres" % [folder.trim_suffix("/"), _free_name(folder, clean)]
		var copy: FurLook = source.duplicate()
		if ResourceSaver.save(copy, path) == OK:
			copy.take_over_path(path)
			done.call(copy)
		else:
			push_error("Could not save the new fur variant to " + path)
		dialog.queue_free()
	dialog.confirmed.connect(accept)
	dialog.canceled.connect(dialog.queue_free)
	field.text_submitted.connect(func(_t: String) -> void:
		dialog.hide()
		accept.call())
	editor.get_base_control().add_child(dialog)
	dialog.popup_centered()
	field.select_all()
	field.grab_focus()


# "White Long Fur" -> "White Long Fur 2" when that name is taken, and so on.
static func _free_name(folder: String, wanted: String) -> String:
	var name := wanted
	var n := 2
	while FileAccess.file_exists("%s/%s.tres" % [folder.trim_suffix("/"), name]):
		name = "%s %d" % [wanted.rstrip("0123456789 "), n]
		n += 1
	return name
