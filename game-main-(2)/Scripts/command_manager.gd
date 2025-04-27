extends Node

@export var commands: Dictionary = {
	"pata pata pata pon": "stabilize",
	"pon pon pata pon": "counter_attack",
	"chaka chaka pata pon": "shield",
	"don don chaka chaka": "calm_enemy"
}

var command_queue: Array = []
var max_command_length: int = 4

func _process(delta):
	if Input.is_action_just_pressed("pata"):
		register_beat("pata")
	if Input.is_action_just_pressed("pon"):
		register_beat("pon")
	if Input.is_action_just_pressed("don"):
		register_beat("don")
	if Input.is_action_just_pressed("chaka"):
		register_beat("chaka")

func register_beat(beat_sound: String) -> void:
	command_queue.append(beat_sound)
	if command_queue.size() > max_command_length:
		command_queue.pop_front()  # Keep queue size limited
	
	print("Current Queue:", command_queue)  # 🔥 Debugging print
	check_command()

func check_command() -> void:
	var command_string = " ".join(command_queue)
	print("Checking command:", command_string)  # 🔥 Debugging print

	if command_string in commands:
		print("✅ Command recognized:", commands[command_string])  # 🔥 Debugging print
		execute_command(commands[command_string])
	else:
		print("❌ No command matched.")

func execute_command(action: String) -> void:
	var battle_node = get_tree().get_first_node_in_group("battle")
	if battle_node:
		battle_node.process_command(action)
	else:
		print("⚠️ No battle node found to process the action.")
