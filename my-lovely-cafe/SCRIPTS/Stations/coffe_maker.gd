extends Node3D
@onready var snap_zone: XRToolsSnapZone = $SnapZone
@onready var button: XRToolsInteractableAreaButton = $Button  # wherever you add it

func _ready() -> void:
	button.button_pressed.connect(_on_button_pressed)

func _on_button_pressed(_button) -> void:
	if not snap_zone.has_snapped_object():
		return  # no cup, nothing happens
	var glass = snap_zone.picked_up_object
	_brew(glass)

func _brew(glass: Node3D) -> void:
	# animate the "Coffee" mesh's liquid_fill shader (fill_amount 0 → 1) that's
	# already sitting in GlassPickup.tscn, then mark the glass as filled
	pass
