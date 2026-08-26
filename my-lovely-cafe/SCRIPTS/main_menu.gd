extends CanvasLayer

@export_file("*.tscn") var new_game_scene: String = "res://! SCENES/! Game/!Start.tscn"

func _ready() -> void:
	$"Level Select".hide()

func _on_btn_start_pressed() -> void:
	# check if there are previous saves and play
	
	# start a new game
	new_game()

func _on_btn_new_game_pressed() -> void:
	new_game()

func new_game() -> void:
	get_tree().change_scene_to_file(new_game_scene)

func _on_btn_level_select_pressed() -> void:
	$"Level Select".show()

func _on_btn_exit_pressed() -> void:
	# exit out of game no save
	get_tree().quit()

func _on_btn_back_to_main_menu_pressed() -> void:
	$"Level Select".hide()
