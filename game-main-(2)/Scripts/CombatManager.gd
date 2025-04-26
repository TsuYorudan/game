extends Node

func _ready():
	var rhythm_input = get_tree().get_first_node_in_group("rhythm_input")
	if rhythm_input:
		rhythm_input.command_entered.connect(_on_command_entered)

func _on_command_entered(command: Array[String]):
	print("Player entered:", command)
	
	if command == ["pata", "pon", "don", "chaka"]:
		print("Powerful Attack Executed!")
