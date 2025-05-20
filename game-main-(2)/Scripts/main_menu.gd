class_name mainMenu
extends Control

@onready var main_buttons: VBoxContainer = $MarginContainer/mainButtons
@onready var settings_menu: Panel = $settingsMenu
@onready var transition_layer: CanvasLayer = $"../TransitionScreen"
@onready var transition_color_rect: ColorRect = $TransitionScreen/ColorRect

var _quit_after_transition := false

func _ready():
	$MarginContainer/mainButtons/HBoxContainer3/Play.grab_focus()
	main_buttons.visible = true
	settings_menu.visible = false

	# Connect transition signal
	transition_layer.connect("on_transition_finished", Callable(self, "_on_transition_finished"))

func _on_play_pressed() -> void:
	$start.play()
	transition_layer.transition()
	await transition_layer.on_transition_finished
	get_tree().change_scene_to_file("res://Scenes/gameplay.tscn")

func _on_settings_pressed() -> void:
	main_buttons.visible = false
	settings_menu.visible = true

func _on_quit_pressed() -> void:
	_quit_after_transition = true
	transition_layer.transition()

func _on_back_pressed() -> void:
	main_buttons.visible = true
	settings_menu.visible = false

func _on_transition_finished() -> void:
	if _quit_after_transition:
		get_tree().quit()
