class_name mainMenu
extends Control

@onready var main_buttons: VBoxContainer = $MarginContainer/mainButtons
@onready var settings_menu: Panel = $settingsMenu
@onready var transition_layer: CanvasLayer = $"../TransitionScreen"
@onready var transition_color_rect: ColorRect = $TransitionScreen/ColorRect

func _ready():
	$MarginContainer/mainButtons/HBoxContainer3/Play.grab_focus()
	main_buttons.visible = true
	settings_menu.visible = false
	if transition_color_rect:
		transition_color_rect.visible = false
	else:
		print("ColorRect not found! Check node names and paths.")
	
	# Connect using Callable
	transition_layer.connect("on_transition_finished", Callable(self, "_on_transition_finished"))


func _on_play_pressed() -> void:
	TransitionScreen.transition()
	await TransitionScreen.on_transition_finished
	$start.play()                         # Start music
	transition_layer.fade_out()           # Start fading to black

	# Wait until fade to black is done
	await transition_layer.on_fade_out_finished

	# Wait until music finishes
	await $start.finished

	# Change scene to gameplay
	get_tree().change_scene_to_file("res://Scenes/gameplay.tscn")

	transition_layer.fade_in()
	await transition_layer.on_fade_in_finished 



func _on_settings_pressed() -> void:
	TransitionScreen.transition()
	await TransitionScreen.on_transition_finished
	main_buttons.visible = false
	settings_menu.visible = true

func _on_quit_pressed() -> void:
	TransitionScreen.transition()
	await TransitionScreen.on_transition_finished
	get_tree().quit()

	transition_layer.transition()
	# Set a flag so we know we want to quit after transition
	_quit_after_transition = true

func _on_back_pressed() -> void:
	TransitionScreen.transition()
	await TransitionScreen.on_transition_finished
	main_buttons.visible = true
	settings_menu.visible = false

var _quit_after_transition := false

func _on_transition_finished() -> void:
	if _quit_after_transition:
		get_tree().quit()
