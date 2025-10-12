class_name mainMenu
extends Control

@onready var main_buttons: VBoxContainer = $MarginContainer/mainButtons
@onready var settings_menu: Panel = $settingsMenu
@onready var start_music: AudioStreamPlayer = $start
@onready var play: Button = $MarginContainer/mainButtons/HBoxContainer3/Play


var _quit_after_transition := false

func _ready():
	$MarginContainer/mainButtons/HBoxContainer3/Play.grab_focus()
	main_buttons.visible = true
	settings_menu.visible = false
	
	if SaveLoad.existing_file():
		play.text = "CONTINUE"
	else: 
		play.text = "NEW GAME"

func _on_play_pressed() -> void:
	start_music.play()

	TransitionScreen.fade_out()
	await TransitionScreen.on_fade_out_finished

	await start_music.finished

	if SaveLoad.existing_file():
		SaveLoad.load_game()
		get_tree().change_scene_to_file("res://Scenes/gameplay.tscn")

	else:
		SaveLoad.reset_game()
		get_tree().change_scene_to_file("res://Scenes/gameplay.tscn")

	TransitionScreen.fade_in()
	await TransitionScreen.on_fade_in_finished

func _on_settings_pressed() -> void:
	TransitionScreen.fade_out()
	await TransitionScreen.on_fade_out_finished

	main_buttons.visible = false
	settings_menu.visible = true

	TransitionScreen.fade_in()
	await TransitionScreen.on_fade_in_finished

func _on_back_pressed() -> void:
	TransitionScreen.fade_out()
	await TransitionScreen.on_fade_out_finished

	main_buttons.visible = true
	settings_menu.visible = false

	TransitionScreen.fade_in()
	await TransitionScreen.on_fade_in_finished

func _on_quit_pressed() -> void:
	_quit_after_transition = true
	TransitionScreen.fade_out()
	await TransitionScreen.on_fade_out_finished
	get_tree().quit()
