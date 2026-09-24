@tool
extends DialogueEvent
class_name EventTrigger

@export var delayed_trigger: bool = false:
	set(value):
		delayed_trigger = value
		notify_property_list_changed()

@export var delay_time: float = 2.0

@export var trigger_object_name: String

#THING THAT SHOWS THE SETTING ON TOGGLE TRUE
func _validate_property(property: Dictionary) -> void:
	if property.name == "delay_time" and not delayed_trigger:
		property.usage &= ~PROPERTY_USAGE_EDITOR
