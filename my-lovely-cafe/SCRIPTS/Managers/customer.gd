extends Node3D

enum State { ENTERING, WAITING_TO_ORDER, ORDERING, WAITING_FOR_ORDER, VERIFYING, LEAVING_HAPPY, LEAVING_UPSET }

signal order_placed(drink: GameManager.DrinkType)

var state: State = State.ENTERING
var desired_drink: GameManager.DrinkType

func place_order() -> void:
	desired_drink = [GameManager.DrinkType.COFFEE].pick_random()  # only one option for now
	state = State.WAITING_TO_ORDER
	order_placed.emit(desired_drink)

func receive_drink(made_drink: GameManager.DrinkType, payment: int) -> void:
	state = State.VERIFYING
	var correct := made_drink == desired_drink
	if correct:
		state = State.LEAVING_HAPPY
	else:
		state = State.LEAVING_UPSET
	LevelManager.register_order_result(correct, payment)
