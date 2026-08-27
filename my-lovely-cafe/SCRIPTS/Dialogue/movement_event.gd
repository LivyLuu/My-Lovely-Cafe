# movement_event.gd
extends DialogueEvent
class_name MovementEvent

@export var max_time: float = 0.0
@export var actors_in_scene: Array[CharacterData] = []
