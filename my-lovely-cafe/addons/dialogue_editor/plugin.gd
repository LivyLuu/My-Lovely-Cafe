@tool
extends EditorPlugin

var main_panel_instance: Control


func _enter_tree() -> void:
	main_panel_instance = _build_panel()
	get_editor_interface().get_editor_main_screen().add_child(main_panel_instance)
	_make_visible(false)


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
	label.text = "Dialogue Editor"
	label.add_theme_color_override("font_color", Color.PURPLE)
	layout.add_child(label)

	var text_edit := TextEdit.new()
	text_edit.name = "DialogueText"
	text_edit.size_flags_vertical = Control.SIZE_EXPAND_FILL
	text_edit.placeholder_text = "Write your dialogue here..."
	layout.add_child(text_edit)

	return panel
