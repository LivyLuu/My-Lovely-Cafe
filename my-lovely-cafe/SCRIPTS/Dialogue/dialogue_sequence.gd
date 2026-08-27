extends Node3D
class_name DialogueSequence

@export var events: Array[DialogueEvent] = []
@onready var speaker_label: Label3D = $DialogueDisplay/SpeakerName
@onready var dialogue_label: Label3D = $DialogueDisplay/DialogueText

var _event_index: int = 0
var _line_index: int = 0


func _ready() -> void:
	_show_current_beat()


func _show_current_beat() -> void:
	if _event_index >= events.size():
		return

	var event := events[_event_index]
	if event is TextEvent:
		speaker_label.text = event.character_id
		dialogue_label.text = event.events[_line_index]
	elif event is OptionsEvent:
		pass


func advance() -> void:
	var event := events[_event_index]
	if event is TextEvent:
		_line_index += 1
		if _line_index >= event.events.size():
			_line_index = 0
			_event_index += event.skip_ahead
		_show_current_beat()
