extends Node

var brewing_storage = false

func update_brewing(brewing):
	brewing_storage = brewing

signal brewing_started() 
signal brewing_ended() 
signal customer_is_ordering()
signal cup_filled()

func customer_starts_walking():
	pass
func customer_stops_walking():
	pass
