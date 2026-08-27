# text_event.gd
extends DialogueEvent
class_name TextEvent
#
#enum Expression { HAPPY, NEUTRAL, SAD, ANGRY }

@export var character_speaking: CharacterData
@export var line_text: String
#@export var character_expression: Expression = Expression.NEUTRAL
@export var skip_ahead: int = 1
