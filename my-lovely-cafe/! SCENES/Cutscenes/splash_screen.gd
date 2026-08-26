extends Node3D

## Splash intro animation
##
## Slides the splash art in, holds briefly, then fades to black using
## XRToolsFade. Self-contained to this scene — does not touch the
## player's actual XROrigin3D/gameplay setup at all.

@export var slide_distance: float = 20.0
@export var slide_duration: float = 1.2
@export var hold_duration: float = 1.5
@export var fade_duration: float = 1.0

@onready var loading_screen: Node3D = $LoadingScreen
@onready var splash_mesh: MeshInstance3D = $LoadingScreen/SplashScreen
@onready var xr_camera: XRCamera3D = $XROrigin3D/XRCamera3D


func _ready() -> void:
	loading_screen.set_camera(xr_camera)

	var rest_position := splash_mesh.position
	splash_mesh.position = rest_position + Vector3(-slide_distance, 0, 0)

	var tween := create_tween()
	tween.tween_property(splash_mesh, "position", rest_position, slide_duration) \
		.set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	tween.tween_interval(hold_duration)
	tween.tween_method(_set_fade, 0.0, 1.0, fade_duration)


func _set_fade(amount: float) -> void:
	XRToolsFade.set_fade("splash", Color(0, 0, 0, amount))
