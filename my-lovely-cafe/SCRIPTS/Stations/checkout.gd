extends Area3D

func _on_body_entered(body: Node3D) -> void:
	if body.is_in_group("coffee"):
		SignalBus.coffee_ready_to_sell.emit()

func _ready():
	SignalBus.sell_items_checkout.connect(sell_items_in_collision)
	
func sell_items_in_collision():
	print ("selling items in collision from checkout script!")
