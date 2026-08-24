extends Node

signal level_complete(won: bool)

@export var customers_required: int = 2

var customers_served: int = 0
var money_earned_this_level: int = 0

func register_order_result(correct: bool, payment: int) -> void:
	if correct:
		money_earned_this_level += payment
		customers_served += 1
	if customers_served >= customers_required:
		end_level()

func end_level() -> void:
	var did_win := customers_served >= customers_required
	GameManager.complete_level(money_earned_this_level, did_win)
	level_complete.emit(did_win)
