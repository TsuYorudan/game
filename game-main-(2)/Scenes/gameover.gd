class_name gameOver
extends Control

func _on_play_again_pressed() -> void:
	TransitionScreen.fade_out()
	await TransitionScreen.on_fade_out_finished

	get_tree().change_scene_to_file("res://overworld.tscn")

	TransitionScreen.fade_in()
	await TransitionScreen.on_fade_in_finished 

func _on_main_menu_pressed() -> void:
	get_tree().paused = false
	
	TransitionScreen.fade_out()
	await TransitionScreen.on_fade_out_finished
	
	get_tree().change_scene_to_file("res://Scenes/main_menu.tscn")
	
	TransitionScreen.fade_in()
	await TransitionScreen.on_fade_in_finished 
	
		
	


func _on_button_2_pressed() -> void:
	pass # Replace with function body.
