extends Node

signal command_entered(command: Array[String])  # Signal for full input sequence
signal missed_beat()  # Signal when player fails timing

var current_sequence: Array[String] = []
var expecting_response: bool = false  # Is the enemy waiting for input?
var input_tolerance: float = 0.2  # Allow some timing flexibility

func _ready():
	var rhythm_system = get_tree().get_first_node_in_group("rhythm")
	if rhythm_system:
		rhythm_system.beat.connect(_on_beat)

	var enemy = get_tree().get_first_node_in_group("enemy")
	if enemy:
		enemy.rhythm_attack.connect(_on_enemy_attack)

func _on_enemy_attack(pattern: Array[String]):
	""" Enemy plays a rhythm, expecting a response """
	print("Enemy plays:", pattern)
	expecting_response = true
	current_sequence.clear()

func _on_beat():
	""" Handle beat timing: If too late, clear sequence """
	if expecting_response and current_sequence.size() < 4:
		print("Missed Beat!")
		emit_signal("missed_beat")
		expecting_response = false
		current_sequence.clear()

func _input(event):
	""" Detect rhythm inputs and register them """
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
	""" Register an input and check if the sequence is complete """
	current_sequence.append(beat_name)
	print("Input:", beat_name)

	if current_sequence.size() == 4:
		emit_signal("command_entered", current_sequence.duplicate())
		current_sequence.clear()
		expecting_response = false
