extends Node3D

## Drives a 3D Label3D dialogue box from Dialogic's signals instead of
## Dialogic's own Control/CanvasLayer display. Dialogic never touches this
## node directly -- it only knows about "dialogic_dialog_text" style groups,
## which this script deliberately never joins. Everything here is driven by
## Dialogic.Text / Dialogic.Choices signals, so Dialogic's own typewriter,
## portraits and default choice buttons are simply never instanced.

const CHOICE_BUTTON_SCENE := preload("res://! PREFABS/dialogue_choice_button.tscn")

## Strips Dialogic's bbcode-style inline effects (e.g. "[pause=0.5!]",
## "[wait time=\"1.0\"]") since Label3D can't render or time them.
const TAG_REGEX_PATTERN := "\\[[^\\]]*\\]"

@export var left_controller: XRController3D
@export var right_controller: XRController3D
@export var characters_per_second: float = 30.0

@onready var speaker_label: Label3D = $DialogueDisplay/SpeakerName
@onready var dialogue_label: Label3D = $DialogueDisplay/DialogueText
@onready var choices_container: Node3D = $DialogueDisplay/ChoicesContainer

var _tag_regex := RegEx.new()
var _reveal_tween: Tween
var _is_revealing := false
var _choices_active := false
var _current_full_text := ""


func _ready() -> void:
	_tag_regex.compile(TAG_REGEX_PATTERN)

	Dialogic.Text.about_to_show_text.connect(_on_about_to_show_text)
	Dialogic.Text.speaker_updated.connect(_on_speaker_updated)
	Dialogic.Choices.question_shown.connect(_on_question_shown)
	Dialogic.timeline_ended.connect(_on_timeline_ended)

	if left_controller:
		left_controller.button_pressed.connect(_on_button_pressed)
	if right_controller:
		right_controller.button_pressed.connect(_on_button_pressed)

	speaker_label.text = ""
	dialogue_label.text = ""


func _on_timeline_ended() -> void:
	# make the ending actually visible instead of the box just sitting on
	# the last line forever
	_choices_active = false
	_clear_choices()
	if _reveal_tween:
		_reveal_tween.kill()
	_is_revealing = false
	speaker_label.text = ""
	dialogue_label.text = ""


func _on_button_pressed(action_name: String) -> void:
	if action_name != "trigger_click":
		return
	if _choices_active:
		# choices are answered by touching a choice button, not by trigger-click
		return
	if _is_revealing:
		_finish_reveal()
	else:
		Dialogic.handle_next_event()


func _on_speaker_updated(character: DialogicCharacter) -> void:
	if character:
		speaker_label.text = character.display_name
		speaker_label.modulate = character.color if character.color != Color() else Color(0.40875384, 0.3469108, 0.53484225, 1)
	else:
		speaker_label.text = ""


func _on_about_to_show_text(info: Dictionary) -> void:
	var raw_text: String = info.get("text", "")
	var clean_text := _tag_regex.sub(raw_text, "", true)
	_start_reveal(clean_text)


func _start_reveal(text: String) -> void:
	_current_full_text = text
	_is_revealing = true
	dialogue_label.text = ""

	if _reveal_tween:
		_reveal_tween.kill()

	var duration := text.length() / characters_per_second
	_reveal_tween = create_tween()
	_reveal_tween.tween_method(_reveal_up_to.bind(text), 0, text.length(), duration)
	_reveal_tween.finished.connect(_on_reveal_finished)


func _reveal_up_to(char_count: int, full_line: String) -> void:
	dialogue_label.text = full_line.substr(0, char_count)


func _on_reveal_finished() -> void:
	_is_revealing = false


func _finish_reveal() -> void:
	if _reveal_tween:
		_reveal_tween.kill()
	dialogue_label.text = _current_full_text
	_is_revealing = false


func _on_question_shown(info: Dictionary) -> void:
	_choices_active = true
	_clear_choices()

	var choices: Array = info.get("choices", [])
	var start_y := -0.12
	var step_y := -0.09

	for i in choices.size():
		var choice: Dictionary = choices[i]
		if not choice.get("visible", true):
			continue

		var button_index: int = choice.get("button_index", i)
		var label_text: String = _tag_regex.sub(choice.get("text", ""), "", true)

		var button := CHOICE_BUTTON_SCENE.instantiate()
		button.button_index = button_index
		button.transform.origin = Vector3(0.0, start_y + step_y * i, 0.0)
		button.chosen.connect(_on_choice_button_pressed)

		choices_container.add_child(button)
		button.set_text(label_text)


func _on_choice_button_pressed(button_index: int) -> void:
	if not _choices_active:
		return
	_choices_active = false
	_clear_choices()
	Dialogic.Choices.select_choice(button_index)


func _clear_choices() -> void:
	for child in choices_container.get_children():
		child.queue_free()
