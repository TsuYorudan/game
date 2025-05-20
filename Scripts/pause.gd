extends Node

@onready var settings_menu: Control = $UI/SettingsMenu

func _ready() -> void:
	settings_menu.visible = false

func _input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		if not get_tree().paused:
			pause_game()
		else:
			unpause_game()

func pause_game() -> void:
	get_tree().paused = true
	settings_menu.visible = true
	settings_menu.process_mode = Node.PROCESS_MODE_ALWAYS  # Ensure it still works while paused

func unpause_game() -> void:
	get_tree().paused = false
	settings_menu.visible = false
