@tool
extends Node3D
class_name DialogueSequence

@export var events: Array[DialogueEvent] = []
@onready var speaker_label: Label3D = $DialogueDisplay/SpeakerName
@onready var dialogue_label: Label3D = $DialogueDisplay/DialogueText
@export var left_controller: XRController3D
@export var right_controller: XRController3D
@export var characters_per_second: float = 30.0
@export var scene_change_after_dialogue: bool = false:
	set(value):
		scene_change_after_dialogue = value
		notify_property_list_changed() 

@export var next_scene: PackedScene

func _validate_property(property: Dictionary) -> void:
	if property.name == "next_scene":
		if scene_change_after_dialogue:
			# Explicitly ensure it resets to visible default settings
			property.usage = PROPERTY_USAGE_DEFAULT
		else:
			# Hide it completely from the editor
			property.usage = PROPERTY_USAGE_NO_EDITOR
			
var _event_index: int = 0
var _line_index: int = 0


func _ready() -> void:
	left_controller.button_pressed.connect(_on_button_pressed)
	right_controller.button_pressed.connect(_on_button_pressed)
	_show_current_beat()

func _on_button_pressed(action_name: String) -> void:
	if action_name == "trigger_click":
		advance()
func _show_current_beat() -> void:
	if _event_index >= events.size():
		_on_dialogue_finished()
		return

	var event := events[_event_index]
	if event is TextEvent:
		speaker_label.text = event.character_id
		_type_line(event.events[_line_index])
	elif event is OptionsEvent:
		pass


func _on_dialogue_finished() -> void:
	if scene_change_after_dialogue:
		get_tree().change_scene_to_packed(next_scene)


func _type_line(line: String) -> void:
	dialogue_label.text = ""

	var duration := line.length() / characters_per_second
	var tween := create_tween()
	tween.tween_method(_reveal_up_to.bind(line), 0, line.length(), duration)


func _reveal_up_to(char_count: int, full_line: String) -> void:
	dialogue_label.text = full_line.substr(0, char_count)


func advance() -> void:
	if _event_index >= events.size():
		return
	var event := events[_event_index]
	if event is TextEvent:
		_line_index += 1
		if _line_index >= event.events.size():
			_line_index = 0
			_event_index += event.skip_ahead
		_show_current_beat()
