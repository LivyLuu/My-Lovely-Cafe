extends StaticBody3D

## A single dialogue choice, clickable via the hand pointer laser --
## same pointer_event/Pointable Objects pattern as cash_register.gd,
## not a physical touch button.

signal pointer_event(event)
signal chosen(button_index: int)

@export var normal_color: Color = Color(0.85, 0.85, 0.95, 1)
@export var hover_color: Color = Color(1.0, 0.85, 0.4, 1)
@export var hover_background_color: Color = Color(1.0, 0.85, 0.4, 0.18)

@onready var label: Label3D = $Label
@onready var background: MeshInstance3D = $Background
@onready var background_material: StandardMaterial3D = background.get_surface_override_material(0)

var button_index: int = 0


func _ready() -> void:
	pointer_event.connect(_on_pointer_event)
	label.modulate = normal_color


func set_text(text: String) -> void:
	label.text = text


func _on_pointer_event(event: XRToolsPointerEvent) -> void:
	match event.event_type:
		XRToolsPointerEvent.Type.ENTERED:
			_set_hovered(true)
		XRToolsPointerEvent.Type.EXITED:
			_set_hovered(false)
		XRToolsPointerEvent.Type.PRESSED:
			chosen.emit(button_index)


func _set_hovered(hovered: bool) -> void:
	label.modulate = hover_color if hovered else normal_color
	background_material.albedo_color = hover_background_color if hovered else Color(1, 1, 1, 0)
