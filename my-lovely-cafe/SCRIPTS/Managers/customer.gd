extends Node3D
class_name Customer

enum State { ENTERING, WAITING_TO_ORDER, ORDERING, WAITING_FOR_ORDER, VERIFYING, LEAVING_HAPPY, LEAVING_UPSET }

signal order_placed(item: MenuItem)
signal order_result(correct: bool, payment: int)
signal customer_starts_walking
signal customer_stops_walking
signal waypoint_reached(marker: Node3D)
signal path_completed

# on ready/spawn get the "path" from the level manager in scene and walk it
var state: State = State.ENTERING
var desired_item: MenuItem
var customer_plans_to_walk: Array[Node3D] = []
var current_index: int = 0
var current_tile

@export var step_delay: float = 0.6  # placeholder pacing between points; swap for a Tween later

func place_order(possible_orders: Array[MenuItem]) -> void:
	desired_item = possible_orders.pick_random()
	state = State.WAITING_TO_ORDER
	order_placed.emit(desired_item)

#func receive_item(served_item: MenuItem) -> void:
	#state = State.VERIFYING
	#var correct := served_item != null and served_item.id == desired_item.id
	#state = State.LEAVING_HAPPY if correct else State.LEAVING_UPSET
	#order_result.emit(correct, desired_item.price)

func start_walking(waypoints: Array[Node3D]) -> void:
	customer_plans_to_walk = waypoints
	current_index = 0
	customer_starts_walking.emit()
	_advance()

func _advance() -> void:
	if current_index >= customer_plans_to_walk.size():
		customer_stops_walking.emit()
		path_completed.emit()
		return

	var next_tile = customer_plans_to_walk[current_index]
	global_position = next_tile.global_position  # placeholder, swap for a Tween later
	current_tile = next_tile
	current_index += 1
	waypoint_reached.emit(next_tile)

	if next_tile.tile_data.tile_type == CafeTile.TileType.ORDER:
		state = State.ORDERING
		customer_stops_walking.emit()
		return  # paused here — level manager / order system resumes it later

	await get_tree().create_timer(step_delay).timeout
	_advance()
