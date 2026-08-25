extends Node
@onready var root_glass = $".."
# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	$".".hide()
	SignalBus.cup_filled.connect(fill_coffee)

func fill_coffee():
	$".".show()
	root_glass.add_to_group("Coffee")
	print("Glass is now consideredpart of coffee group!")
