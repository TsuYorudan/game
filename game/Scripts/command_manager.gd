extends Node

var command_queue = []
var max_command_length = 4

var commands = {

}

func register_beat(beat_sound):
	command_queue.append(beat_sound)
	if command_queue.size() > max_command_length:
		command_queue.pop_front()  # Keep queue size limited

	check_command()

func check_command():
	var command_string = " ".join(command_queue)
	if command_string in commands:
		execute_command(commands[command_string])

func execute_command(action):
	get_tree().get_first_node_in_group("battle").process_command(action)
