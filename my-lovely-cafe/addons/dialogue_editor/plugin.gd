@tool
extends EditorPlugin

const DIALOGUE_SCRIPT_MARKER := "dialogue_sequence.gd"
const SKIP_DIRS := ["addons", ".godot"]

var main_panel_instance: Control
var _scene_list: ItemList
var _found_nodes: Array[Dictionary] = []  # each: {"path": String, "node_name": String}


func _enter_tree() -> void:
	main_panel_instance = _build_panel()
	get_editor_interface().get_editor_main_screen().add_child(main_panel_instance)
	_make_visible(false)
	_refresh_scene_list()


func _exit_tree() -> void:
	if main_panel_instance:
		main_panel_instance.queue_free()
		main_panel_instance = null


func _has_main_screen() -> bool:
	return true


func _make_visible(next_visible: bool) -> void:
	if main_panel_instance:
		main_panel_instance.visible = next_visible


func _get_plugin_name() -> String:
	return "💬Dialogue"


func _build_panel() -> Control:
	var panel := Control.new()
	panel.name = "DialoguePanel"
	panel.set_anchors_preset(Control.PRESET_FULL_RECT)

	var margin := MarginContainer.new()
	margin.set_anchors_preset(Control.PRESET_FULL_RECT)
	margin.add_theme_constant_override("margin_left", 12)
	margin.add_theme_constant_override("margin_top", 12)
	margin.add_theme_constant_override("margin_right", 12)
	margin.add_theme_constant_override("margin_bottom", 12)
	panel.add_child(margin)

	var layout := VBoxContainer.new()
	layout.add_theme_constant_override("separation", 8)
	margin.add_child(layout)

	var label := Label.new()
	label.text = "Dialogue Scenes"
	label.add_theme_color_override("font_color", Color.PURPLE)
	layout.add_child(label)

	var refresh_button := Button.new()
	refresh_button.text = "Refresh List"
	refresh_button.pressed.connect(_refresh_scene_list)
	layout.add_child(refresh_button)

	var list := ItemList.new()
	list.name = "DialogueSceneList"
	list.size_flags_vertical = Control.SIZE_EXPAND_FILL
	list.custom_minimum_size = Vector2(0, 300)
	list.item_selected.connect(_on_scene_item_selected)
	layout.add_child(list)

	_scene_list = list
	return panel


func _refresh_scene_list() -> void:
	_found_nodes = []
	_scan_dir("res://", _found_nodes)
	print("[Dialogue tab] scan found ", _found_nodes.size(), " dialogue node(s): ", _found_nodes)
	if not _scene_list:
		print("[Dialogue tab] _scene_list is null, can't populate the list")
		return
	_scene_list.clear()
	for entry in _found_nodes:
		_scene_list.add_item("%s  —  %s" % [entry.node_name, String(entry.path).get_file()])


func _on_scene_item_selected(index: int) -> void:
	if index < 0 or index >= _found_nodes.size():
		return
	get_editor_interface().open_scene_from_path(_found_nodes[index].path)


func _scan_dir(path: String, results: Array[Dictionary]) -> void:
	var dir := DirAccess.open(path)
	if not dir:
		print("[Dialogue tab] couldn't open directory: ", path, " (error: ", DirAccess.get_open_error(), ")")
		return

	dir.list_dir_begin()
	var file_name := dir.get_next()
	while file_name != "":
		if file_name.begins_with("."):
			file_name = dir.get_next()
			continue

		var full_path := path.path_join(file_name)
		if dir.current_is_dir():
			if not SKIP_DIRS.has(file_name):
				_scan_dir(full_path, results)
		elif file_name.ends_with(".tscn"):
			_find_dialogue_nodes_in_file(full_path, results)

		file_name = dir.get_next()
	dir.list_dir_end()


# Finds every node in this scene file whose script is dialogue_sequence.gd,
# and records its actual node name — not just whether the file matches.
func _find_dialogue_nodes_in_file(scene_path: String, results: Array[Dictionary]) -> void:
	var file := FileAccess.open(scene_path, FileAccess.READ)
	if not file:
		return
	var content := file.get_as_text()
	file.close()

	if not content.contains(DIALOGUE_SCRIPT_MARKER):
		return

	# Find the ext_resource id(s) that point at dialogue_sequence.gd — a scene
	# can reference it more than once under different ids.
	var script_ids: Array[String] = []
	for line in content.split("\n"):
		if line.begins_with("[ext_resource") and line.contains(DIALOGUE_SCRIPT_MARKER):
			var id_start := line.find("id=\"")
			if id_start != -1:
				id_start += 4
				var id_end := line.find("\"", id_start)
				script_ids.append(line.substr(id_start, id_end - id_start))

	if script_ids.is_empty():
		return

	# Split the file into per-node blocks and check each one's body (not just
	# the line right after [node ...]) for a matching script assignment, so
	# this doesn't break if other properties come before "script =".
	for block in content.split("[node ").slice(1):
		var header_end := block.find("]")
		if header_end == -1:
			continue
		var header := block.substr(0, header_end)
		var body := block.substr(header_end)

		var uses_dialogue_script := false
		for id in script_ids:
			if body.contains("script = ExtResource(\"%s\")" % id):
				uses_dialogue_script = true
				break

		if uses_dialogue_script:
			var name_start := header.find("name=\"")
			if name_start != -1:
				name_start += 6
				var name_end := header.find("\"", name_start)
				results.append({
					"path": scene_path,
					"node_name": header.substr(name_start, name_end - name_start),
				})
