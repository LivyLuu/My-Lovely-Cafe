extends Node3D
class_name CoffeeMaker
@onready var snap_zone: XRToolsSnapZone = $SnapZone
@onready var button: XRToolsInteractableAreaButton = $RigidBody3D2/Button
@export var coffee_item: MenuItem
var is_pouring = false

func _on_button_button_pressed(_button: Variant) -> void:
	if not snap_zone.has_snapped_object():
		return  # no cup, nothing happens
	SignalBus.brewing_started.emit()
	$Pour.show()
	is_pouring = true
	$BrewTime.start()


func _on_brew_time_timeout() -> void:
	SignalBus.brewing_ended.emit()
	is_pouring = false
	$Pour.hide()
	_fill_cup()


func _fill_cup() -> void:
	if not snap_zone.has_snapped_object():
		return  # cup was removed mid-brew, nothing to fill
	var glass := snap_zone.picked_up_object
	var contents := glass.get_node("Contents") as ItemContainer
	contents.current_item = coffee_item
	SignalBus.cup_filled.emit()


func _on_snap_zone_has_picked_up(what: Variant) -> void:
	print("coffee maker sees empty cup in snap zone")
	if is_pouring:
		print("filling the cup!")
		SignalBus.cup_filled.emit()
