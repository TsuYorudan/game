extends Boss
class_name DespairBoss

@export var debuff_turns: int = 3
var debuff_remaining: int = 0

func trigger_special() -> void:
	print("💀 DESPAIR SPECIAL TRIGGERED!")
	debuff_remaining = debuff_turns

	var player = get_tree().get_first_node_in_group("player")
	if player:
		player.apply_despair_debuff(debuff_turns)
