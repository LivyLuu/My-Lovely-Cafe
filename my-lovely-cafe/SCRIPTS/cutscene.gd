extends Node3D

var _rest_position: Vector3
# spawn in facing marker 3d direction
@onready var spawn_direction: Marker3D = $Player/starting_direction

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	_rest_position = spawn_direction.position


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass
