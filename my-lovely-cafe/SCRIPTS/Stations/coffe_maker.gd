extends Node3D
class_name CoffeeMaker
@onready var snap_zone: XRToolsSnapZone = $SnapZone
@onready var button: XRToolsInteractableAreaButton = $RigidBody3D2/Button
@export var coffee_item: MenuItem

func _ready() -> void:
	button.button_pressed.connect(_on_button_pressed)

func _on_button_pressed(_button) -> void:
	if not snap_zone.has_snapped_object():
		return  # no cup, nothing happens
	var glass = snap_zone.picked_up_object
	_brew(glass)

func _brew(glass: Node3D) -> void:
	var contents := glass.get_node("Contents") as ItemContainer
	contents.current_item = coffee_item
	# animate the "Coffee" mesh's liquid_fill shader (fill_amount 0 → 1) that's
	# already sitting in GlassPickup.tscn, then mark the glass as filled
	pass


func _on_button_button_pressed(button: Variant) -> void:
	SignalBus.brewing_started.emit() 
	$Pour.show()
	$BrewTime.start()


func _on_brew_time_timeout() -> void:
	SignalBus.brewing_stopped.emit() 
	$Pour.hide()
	SignalBus.brewing_ended.emit() 
