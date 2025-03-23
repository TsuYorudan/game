extends Node

@export var input_tolerance: float = 0.2  # Timing window for valid input
signal command_entered(command)
signal missed_beat()  # If the player fails to respond in time

var current_sequence: Array[String] = []
var expecting_response: bool = false  # Whether an enemy rhythm is playing

func _ready():
    var rhythm_system = get_tree().get_first_node_in_group("rhythm")
    if rhythm_system:
        rhythm_system.beat.connect(_on_beat)

    var enemy = get_tree().get_first_node_in_group("enemy")
    if enemy:
        enemy.rhythm_attack.connect(_on_enemy_attack)

func _on_enemy_attack(pattern: Array[String]):
    """ Called when the enemy plays an attack rhythm """
    print("Enemy plays:", pattern)
    expecting_response = true
    current_sequence.clear()

func _on_beat():
    """ Clears input if the player takes too long to respond """
    if expecting_response and current_sequence.size() < 4:
        print("Missed Beat!")
        emit_signal("missed_beat")
        expecting_response = false
        current_sequence.clear()

func _input(event):
    if event is InputEventKey and event.pressed and expecting_response:
        var pressed_key = event.as_text()
        current_sequence.append(pressed_key)
        print("Input:", pressed_key)

        if current_sequence.size() == 4:
            emit_signal("command_entered", current_sequence.duplicate())
            current_sequence.clear()
            expecting_response = false
