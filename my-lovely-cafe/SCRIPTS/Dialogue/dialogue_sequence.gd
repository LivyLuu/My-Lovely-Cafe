# dialogue_sequence.gd
extends Node3D
class_name DialogueSequence

@export var events: Array[DialogueEvent] = []
@onready var dialogue_box: XRToolsViewport2DIn3D = $DialogueBox

var _event_index: int = 0
var _line_index: int = 0
var _dialogue_label: Label
var _speaker_label: Label


func _ready() -> void:
	var ui := dialogue_box.get_scene_instance()
	_dialogue_label = ui.get_node("Control/MarginContainer2/VBoxContainer/dialogue_txt")
	_speaker_label = ui.get_node("Control/MarginContainer/speaker_name")

	_show_current_beat()


func _show_current_beat() -> void:
	if _event_index >= events.size():
		return

	var event := events[_event_index]
	if event is TextEvent:
		_speaker_label.text = event.character_id
		_dialogue_label.text = event.events[_line_index]
	elif event is OptionsEvent:
		# build option buttons here later
		pass


func advance() -> void:
	var event := events[_event_index]
	if event is TextEvent:
		_line_index += 1
		if _line_index >= event.events.size():
			_line_index = 0
			_event_index += event.skip_ahead
		_show_current_beat()
