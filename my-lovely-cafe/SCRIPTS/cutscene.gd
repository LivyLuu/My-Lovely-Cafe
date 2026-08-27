extends Node3D

@onready var xr_origin: XROrigin3D = $Player/XROrigin3D
@onready var start_xr: XRToolsStartXR = $Player/StartXR
@onready var spawn_direction: Marker3D = $Player/starting_direction


func _ready() -> void:
	start_xr.xr_started.connect(_on_xr_started)


func _on_xr_started() -> void:
	# Rotate the play space to face the marker's direction ;— position is left
	# untouched, only facing changes. Then recenter so the player's real-world
	# orientation lines up with it, no matter which way they were physically
	# standing when the headset started tracking.
	xr_origin.global_rotation = spawn_direction.global_rotation
	XRServer.center_on_hmd(XRServer.RESET_BUT_KEEP_TILT, true)
