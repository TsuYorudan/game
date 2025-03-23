extends Node

@export var commands: Dictionary = {
    "ui_up,ui_up,ui_down,ui_down": "heal",
    "ui_left,ui_right,ui_left,ui_right": "defend",
    "ui_up,ui_up,ui_up,ui_up": "soothe"
}

signal execute_command(action)

func _ready():
    var rhythm_input = get_tree().get_first_node_in_group("rhythm_input")
    if rhythm_input:
        rhythm_input.command_entered.connect(_on_command_entered)

func _on_command_entered(command_sequence):
    var command_string = ",".join(command_sequence)
    if command_string in commands:
        print("Executing Command:", commands[command_string])
        emit_signal("execute_command", commands[command_string])
