extends Node

# recieve signal to play this script

# if delay time = true have it wait for timer end


func _on_timer_timeout() -> void:
	print("timer started for event signal dialogue!")
	#after this time ends send signal
	
