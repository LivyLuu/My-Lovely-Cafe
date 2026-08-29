@tool
extends DialogueEvent
class_name TextEvent

#enum Expression { HAPPY, NEUTRAL, SAD, ANGRY }

var speaker: StringName = &""


func _get_property_list() -> Array[Dictionary]:
	return [CDataOrganizer.get_property("character_id")]


func _get(property: StringName):
	if property == "character_id":
		return speaker
	return null


func _set(property: StringName, value) -> bool:
	if property == "character_id":
		speaker = value
		return true
	return false

#@export var character_expression: Expression = Expression.NEUTRAL
@export var skip_ahead: int = 1
@export var player_focus_location: int = 1
@export var player_focus: bool = false:
	set(value):
		player_focus = value
		notify_property_list_changed()
		
	#THING THAT SHOWS THE SETTING ON TOGGLE TRUE
func _validate_property(property: Dictionary) -> void:
	if property.name == "player_focus_location" and not player_focus:
		property.usage &= ~PROPERTY_USAGE_EDITOR
