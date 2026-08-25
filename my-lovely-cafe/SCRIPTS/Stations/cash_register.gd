extends StaticBody3D

signal pointer_event(event)
const POINTABLE_LAYER := 1 << 20  # layer 21, "Pointable Objects"

func _ready() -> void:
	self.set_collision_layer_value(21, false)
	pointer_event.connect(_on_pointer_event)
	SignalBus.coffee_ready_to_sell.connect(_ready_to_sell)

func _ready_to_sell(_item = null) -> void:
	self.set_collision_layer_value(21, true)

func _on_pointer_event(event: XRToolsPointerEvent) -> void:
	if event.event_type == XRToolsPointerEvent.Type.PRESSED:
		print("Cash Register Recieved a click!")
		# verification logic goes here
