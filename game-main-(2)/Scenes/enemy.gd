extends Node2D
class_name Enemy

var beats := ["pata", "pon", "don", "chaka"]
var attack_sequence: Array = []
var chosen_attack: String = "basic"

signal enemy_attack_started(sequence: Array)
signal enemy_attack_resolved(success: bool, mismatches: int)

func decide_action():
	# Always pick 4 beats randomly (basic attack)
	chosen_attack = "basic"
	attack_sequence.clear()
	for i in range(4):
		attack_sequence.append(beats[randi() % beats.size()])

	print("👾 Enemy decided attack:", attack_sequence)
	emit_signal("enemy_attack_started", attack_sequence)

func perform_action(player_input: Array):
	# Compare player input to enemy sequence
	var mismatches := 0
	for i in range(min(player_input.size(), attack_sequence.size())):
		if player_input[i] != attack_sequence[i]:
			mismatches += 1

	var success := mismatches == 0
	if success:
		print("🛡️ Player successfully countered enemy attack!")
	else:
		print("💥 Player failed! Mismatches:", mismatches)

	emit_signal("enemy_attack_resolved", success, mismatches)
