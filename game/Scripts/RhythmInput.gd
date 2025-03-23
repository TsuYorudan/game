extends Node

@export var input_tolerance: float = 0.2  # Timing window for a valid beat
@export var valid_inputs: Array[String] = ["ui_up", "ui_down", "ui_left", "ui_right"]

signal command_entered(command)

var current_sequence: Array[String] = []

func _ready():
    var rhythm_system = get_tree().get_first_node_in_group("rhythm")
    if rhythm_system:
        rhythm_system.beat.connect(_on_beat)

func _on_beat():
    # Clear sequence if no input was registered on the last beat
    if current_sequence.size() < 4:
        current_sequence.clear()

func _input(event):
    if event is InputEventKey and event.pressed:
        var pressed_key = event.as_text()
        if pressed_key in valid_inputs:
            current_sequence.append(pressed_key)
            print("Input registered:", pressed_key)

        if current_sequence.size() == 4:
            emit_signal("command_entered", current_sequence.duplicate())
            current_sequence.clear()
