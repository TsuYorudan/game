extends Node2D
class_name Enemy

# =====================
# Beats
# =====================
var beat_pool: Array = ["pata", "pon", "don", "chaka"]
var sequence: Array = []

signal sequence_played(sequence: Array)
signal attack_resolved(damage: int)
signal hpchange  # signal for health changes

# =====================
# Stats
# =====================
@export var max_hp: int = 10
var current_hp: int

@export var attack_power: int = 1  # can be used for future damage calculations
var is_dead: bool = false

# =====================
# Audio players
# =====================
@export var pata_sound: AudioStreamPlayer
@export var pon_sound: AudioStreamPlayer
@export var don_sound: AudioStreamPlayer
@export var chaka_sound: AudioStreamPlayer

# =====================
# BeatBar reference
# =====================
var beatbar: Node = null

# Internal flag for awaiting beat
var _beat_done_flag: bool = false

# =====================
# Initialization
# =====================
func _ready():
	current_hp = max_hp
	beatbar = get_tree().get_first_node_in_group("beatbar")

# =====================
# Beat sequence
# =====================
func generate_sequence(length: int = 4) -> void:
	sequence.clear()
	for i in range(length):
		sequence.append(beat_pool[randi() % beat_pool.size()])
	print("👾 Enemy sequence generated:", sequence)

func get_sequence() -> Array:
	return sequence.duplicate()

func play_sequence(rhythm_system: Node) -> void:
	if sequence.is_empty():
		print("⚠️ No enemy sequence to play.")
		return

	print("🎶 Enemy playing sequence:", sequence)

	if beatbar:
		beatbar.is_enemy_turn = true
		beatbar.start_phase()

	for beat in sequence:
		match beat:
			"pata":
				if pata_sound: pata_sound.play()
			"pon":
				if pon_sound: pon_sound.play()
			"don":
				if don_sound: don_sound.play()
			"chaka":
				if chaka_sound: chaka_sound.play()

		if beatbar:
			beatbar.call("register_action_mark", true, beat)

		if rhythm_system:
			await wait_one_beat(rhythm_system)

	if beatbar:
		beatbar.end_phase()
		beatbar.is_enemy_turn = false

	emit_signal("sequence_played", sequence)

func wait_one_beat(rhythm_system: Node) -> void:
	if not rhythm_system:
		return
	_beat_done_flag = false
	var conn = Callable(self, "_on_beat_done")
	rhythm_system.connect("beat", conn, CONNECT_ONE_SHOT)
	while not _beat_done_flag:
		await get_tree().process_frame

func _on_beat_done(_beat_count: int, _timestamp: int) -> void:
	_beat_done_flag = true

# =====================
# Combat
# =====================
func resolve_attack(player_input: Array) -> int:
	var damage := 0
	for i in range(min(sequence.size(), player_input.size())):
		if sequence[i] != player_input[i]:
			damage += 1
	if player_input.size() < sequence.size():
		damage += sequence.size() - player_input.size()

	emit_signal("attack_resolved", damage)
	return damage

# Take damage
func take_damage(amount: int = 1) -> void:
	if is_dead:
		return

	current_hp = max(current_hp - amount, 0)
	emit_signal("hpchange")
	print("Enemy took", amount, "damage! Current HP:", current_hp)

	if current_hp <= 0:
		die()

# Heal
func heal(amount: int = 1) -> void:
	if is_dead:
		return

	current_hp = min(current_hp + amount, max_hp)
	emit_signal("hpchange")
	print("Enemy healed", amount, "HP. Current HP:", current_hp)

# Death
func die() -> void:
	if is_dead:
		return

	is_dead = true
	print("Enemy has been defeated!")
	# You can play death animation, disable the node, or queue_free()
	# For example:
	# sprite.play("death")
	queue_free()
