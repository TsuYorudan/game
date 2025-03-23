extends Node

@export var commands: Dictionary = {
    "pata,pata,pata,pon": "stabilize",
    "pon,pon,pata,pon": "counter_attack",
    "chaka,chaka,pata,pon": "shield",
    "don,don,chaka,chaka": "calm_enemy"
}

signal execute_command(action)
signal missed_beat()  # Emits when the player fails a rhythm

var enemy_pattern: Array[String] = []  # Stores the enemy's attack rhythm

func _ready():
    var rhythm_input = get_tree().get_first_node_in_group("rhythm_input")
    if rhythm_input:
        rhythm_input.command_entered.connect(_on_command_entered)

    var enemy = get_tree().get_first_node_in_group("enemy")
    if enemy:
        enemy.rhythm_attack.connect(_on_enemy_attack)

func _on_enemy_attack(pattern: Array[String]):
    """ Stores the enemy's attack pattern for call-and-response battles """
    enemy_pattern = pattern
    print("Enemy plays:", ",".join(pattern))

func _on_command_entered(command_sequence):
    """ Checks if the player's response matches the enemy's call """
    var command_string = ",".join(command_sequence)
    
    if command_string == ",".join(enemy_pattern):
        print("Perfect Match! Executing:", commands.get(command_string, "Unknown"))
        emit_signal("execute_command", commands.get(command_string, "Unknown"))
    else:
        print("Missed Beat! Command Failed.")
        emit_signal("missed_beat")
