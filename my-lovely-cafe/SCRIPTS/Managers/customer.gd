extends Node3D


enum State { ENTERING, WAITING_TO_ORDER, ORDERING, WAITING_FOR_ORDER, VERIFYING, LEAVING_HAPPY, LEAVING_UPSET }
signal order_placed(item: MenuItem)
signal order_result(correct: bool, payment: int)

@export var possible_orders: Array[MenuItem] = []   # drag coffee.tres in here
var state: State = State.ENTERING
var desired_item: MenuItem

func place_order() -> void:
	desired_item = possible_orders.pick_random()
	state = State.WAITING_TO_ORDER
	order_placed.emit(desired_item)

func receive_item(served_item: MenuItem) -> void:
	state = State.VERIFYING
	var correct := served_item != null and served_item.id == desired_item.id
	state = State.LEAVING_HAPPY if correct else State.LEAVING_UPSET
	order_result.emit(correct, desired_item.price)
