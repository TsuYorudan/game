extends Node

@export var input_tolerance: float = 0.2  # Allowed timing margin
signal command_entered(command)
signal missed_beat()

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
    """ Enemy plays a rhythm, expecting the player to respond """
    print("Enemy plays:", pattern)
    expecting_response = true
    current_sequence.clear()

func _on_beat():
    """ Clears input if the player takes too long """
    if expecting_response and current_sequence.size() < 4:
        print("Missed Beat!")
        emit_signal("missed_beat")
        expecting_response = false
        current_sequence.clear()

func _input(event):
    if expecting_response:
        if event.is_action_pressed("pata"):
            register_input("pata")
        elif event.is_action_pressed("pon"):
            register_input("pon")
        elif event.is_action_pressed("don"):
            register_input("don")
        elif event.is_action_pressed("chaka"):
            register_input("chaka")

func register_input(beat_name: String):
    """ Stores the input and checks if the sequence is complete """
    current_sequence.append(beat_name)
    print("Input:", beat_name)

    if current_sequence.size() == 4:
        emit_signal("command_entered", current_sequence.duplicate())
        current_sequence.clear()
        expecting_response = false
