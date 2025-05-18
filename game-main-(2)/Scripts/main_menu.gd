class_name mainMenu
extends Control

@onready var main_buttons: VBoxContainer = $MarginContainer/mainButtons
@onready var settings_menu: Panel = $settingsMenu

func _ready():
	$MarginContainer/mainButtons/HBoxContainer3/Play.grab_focus()
	
	main_buttons.visible = true
	settings_menu.visible = false


func _on_play_pressed() -> void:
	get_tree().change_scene_to_file("res://Scenes/gameplay.tscn")


func _on_settings_pressed() -> void:
	main_buttons.visible = false
	settings_menu.visible = true


func _on_quit_pressed() -> void:
	get_tree().quit()


func _on_back_pressed() -> void:
	main_buttons.visible = true
	settings_menu.visible = false
