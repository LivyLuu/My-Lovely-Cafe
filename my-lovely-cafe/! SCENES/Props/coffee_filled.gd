extends Node

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	$".".hide()
	SignalBus.cup_filled.connect(fill_coffee)

func fill_coffee():
	$".".show()
