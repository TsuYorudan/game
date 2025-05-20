extends Node

@onready var settings_menu: Control = $UI2/pause
@onready var resume_button: Button = settings_menu.get_node("back")
@onready var main_menu_button: Button = settings_menu.get_node("MarginContainer/VBoxContainer/HBoxContainer3/Leave")

func _ready() -> void:
	TransitionScreen.fade_in()

	settings_menu.visible = false
	settings_menu.process_mode = Node.PROCESS_MODE_ALWAYS

	resume_button.pressed.connect(self._on_resume_pressed)
	main_menu_button.pressed.connect(self._on_main_menu_pressed)

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		if get_tree().paused:
			unpause_game()
		else:
			pause_game()

func pause_game() -> void:
	get_tree().paused = true
	settings_menu.visible = true

func unpause_game() -> void:
	get_tree().paused = false
	settings_menu.visible = false

func _on_resume_pressed() -> void:
	unpause_game()

func _on_main_menu_pressed() -> void:
	get_tree().paused = false
	get_tree().change_scene_to_file("res://Scenes/main_menu.tscn")
