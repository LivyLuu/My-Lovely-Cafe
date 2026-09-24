extends Node3D

## Test harness for the Dialogic VR integration. Reuses the same spawn-facing
## recenter trick as cutscene.gd, then kicks off a Dialogic timeline once the
## player is actually in headset instead of relying on the old custom
## DialogueSequence/TextEvent resource array.

@onready var xr_origin: XROrigin3D = $Player/XROrigin3D
@onready var start_xr: XRToolsStartXR = $Player/StartXR
@onready var spawn_direction: Marker3D = $Player/starting_direction


func _ready() -> void:
	start_xr.xr_started.connect(_on_xr_started)
	Dialogic.timeline_ended.connect(_on_timeline_ended)


func _on_xr_started() -> void:
	xr_origin.global_rotation = spawn_direction.global_rotation
	XRServer.center_on_hmd(XRServer.RESET_BUT_KEEP_TILT, true)
	Dialogic.start_timeline("dialogic_vr_test")


func _on_timeline_ended() -> void:
	print("[DialogicTest] timeline ended")
