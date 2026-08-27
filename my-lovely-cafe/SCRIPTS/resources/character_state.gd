extends Resource
class_name CharacterState

enum Mood { HAPPY, NEUTRAL, SAD, ANGRY }
@export var mood: Mood = Mood.NEUTRAL
@export var relationship_points: int = 0
