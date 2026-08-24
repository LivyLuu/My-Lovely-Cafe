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
	return "Dialogue"


func _build_panel() -> Control:
	var panel := Control.new()
	panel.name = "DialoguePanel"
	panel.set_anchors_preset(Control.PRESET_FULL_RECT)

	var label := Label.new()
	label.text = "Dialogue Editor — coming soon"
	label.set_anchors_preset(Control.PRESET_CENTER)
	panel.add_child(label)

	return panel
