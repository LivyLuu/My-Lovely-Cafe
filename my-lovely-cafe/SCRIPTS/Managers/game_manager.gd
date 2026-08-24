extends Node

enum DrinkType { NONE, COFFEE, MILK, LATTE }

signal money_changed(new_total: int)

var total_money: int = 0
var current_level: int = 1
var highest_level_unlocked: int = 1

func add_money(amount: int) -> void:
	total_money += amount
	money_changed.emit(total_money)

func complete_level(money_earned: int, did_win: bool) -> void:
	add_money(money_earned)
	if did_win and current_level == highest_level_unlocked:
		highest_level_unlocked += 1
