extends Node3D

var xr_interface: XRInterface

func _ready():
	# Start black — the splash screen faded to black before handing off to us,
	# so we pick up from there and fade ourselves in once ready.
	XRToolsFade.set_fade("splash", Color(0, 0, 0, 1))

	xr_interface = XRServer.find_interface("OpenXR")
	if xr_interface and (xr_interface.is_initialized() or xr_interface.initialize()):
		print("OpenXR initialized successfully")

		# Turn off v-sync!
		DisplayServer.window_set_vsync_mode(DisplayServer.VSYNC_DISABLED)

		# Change our main viewport to output to the HMD
		get_viewport().use_xr = true
	else:
		print("OpenXR not initialized, please check if your headset is connected")

	var tween := create_tween()
	tween.tween_method(_set_fade, 1.0, 0.0, 1.0)

	#$UI/OrderBubble.hide()


func _set_fade(amount: float) -> void:
	XRToolsFade.set_fade("splash", Color(0, 0, 0, amount))
