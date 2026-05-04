extends Control

func _on_new_game_button_pressed():
	get_tree().change_scene_to_file("uid://lvq3qltn2day")
	
func _on_exit_button_pressed():
	get_tree().quit()

func _on_exit_game_button_pressed():
	pass # Replace with function body.
