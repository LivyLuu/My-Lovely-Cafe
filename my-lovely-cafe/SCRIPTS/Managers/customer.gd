extends Node3D

enum State { ENTERING, WAITING_TO_ORDER, ORDERING, WAITING_FOR_ORDER, VERIFYING, LEAVING_HAPPY, LEAVING_UPSET }

#signal order_placed(item: MenuItem)
#signal order_result(correct: bool, payment: int)

signal customer_starts_walking
signal customer_stops_walking
signal waypoint_reached(marker: Marker3D)
signal path_completed

# on ready/spawn get the "path" from the level manager in scene and walk it
var state: State = State.ENTERING
var desired_item: MenuItem
var customer_plans_to_walk: Array[Node3D] = []
var current_index: int = 0
var current_tile

#func place_order() -> void:
	#desired_item = possible_orders.pick_random()
	#state = State.WAITING_TO_ORDER
	#order_placed.emit(desired_item)
#
#func receive_item(served_item: MenuItem) -> void:
	#state = State.VERIFYING
	#var correct := served_item != null and served_item.id == desired_item.id
	#state = State.LEAVING_HAPPY if correct else State.LEAVING_UPSET
	#order_result.emit(correct, desired_item.price)

func start_walking(waypoints: Array[Node3D]) -> void:
	path = waypoints
	path_index = 0
	global_position = path[0].global_position
	_advance()

func _advance() -> void:
	path_index += 1
	if path_index >= path.size():
		return
	global_position = path[path_index].global_position  # placeholder, swap for a Tween latern
