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
@export_file("*.tscn") var next_scene: String = "res://! SCENES/! Game/!Start.tscn"

@onready var loading_screen: Node3D = $LoadingScreen
@onready var splash_mesh: MeshInstance3D = $LoadingScreen/SplashScreen
@onready var xr_camera: XRCamera3D = $XROrigin3D/XRCamera3D
@onready var start_xr: XRToolsStartXR = $StartXR

var _rest_position: Vector3


func _ready() -> void:
	loading_screen.set_camera(xr_camera)

	_rest_position = splash_mesh.position
	splash_mesh.position = _rest_position + Vector3(-slide_distance, 0, 0)

	start_xr.xr_started.connect(_on_xr_started)


func _on_xr_started() -> void:
	# Recenter so the player faces forward — toward the splash art —
	# no matter which physical direction they were standing when the
	# headset started tracking.
	XRServer.center_on_hmd(XRServer.RESET_BUT_KEEP_TILT, true)

	var tween := create_tween()
	tween.tween_property(splash_mesh, "position", _rest_position, slide_duration) \
		.set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	tween.tween_interval(hold_duration)
	tween.tween_method(_set_fade, 0.0, 1.0, fade_duration)
	tween.tween_callback(_go_to_next_scene)


func _go_to_next_scene() -> void:
	# Screen is fully black at this point, so the swap itself is invisible.
	# !start.gd picks up from here and fades itself back in once ready.
	get_tree().change_scene_to_file(next_scene)


func _set_fade(amount: float) -> void:
	XRToolsFade.set_fade("splash", Color(0, 0, 0, amount))
