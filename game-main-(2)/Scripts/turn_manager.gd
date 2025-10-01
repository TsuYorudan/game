extends Node

# Turn phases
enum TurnPhase { PREBATTLE, PLAYER_INPUT, PLAYER_RESOLUTION, ENEMY_INPUT, ENEMY_RESOLUTION, END }

var current_turn: String = "PLAYER"
var phase: TurnPhase = TurnPhase.PREBATTLE

signal phase_changed(phase: String)

@export var prebattle_beats: int = 4   # number of beats before fight starts
var beat_count: int = 0

@onready var rhythm_system: Node = get_tree().get_first_node_in_group("rhythm")
@onready var countdown_label: Label = $"../CanvasLayer/Control/CountdownLabel"
@onready var turn_label: Label = $"../CanvasLayer/Control/TurnLabel"

# === Enemy data ===
var enemy_sequence: Array = []
var player_response: Array = []
var beat_pool: Array = ["pata", "pon", "don", "chaka"]

# =====================
# One-beat rest tied to RhythmSystem
# =====================
signal _beat_rest_done

func wait_one_beat() -> void:
	if rhythm_system:
		var connection: Callable = Callable(self, "_on_rest_beat")
		rhythm_system.connect("beat", connection, CONNECT_ONE_SHOT)
		await self._beat_rest_done


func _on_rest_beat(_beat_count: int, _timestamp: int) -> void:
	emit_signal("_beat_rest_done")

# =====================
# Core Functions
# =====================
func _ready():
	# Register so Camera and others can find this node
	if not is_in_group("turn_manager"):
		add_to_group("turn_manager")

	# Initialize UI
	if countdown_label:
		countdown_label.text = ""
		countdown_label.visible = false
	if turn_label:
		turn_label.text = ""
		turn_label.visible = true

	# Start the battle loop
	start_battle()

func start_battle():
	phase = TurnPhase.PREBATTLE
	_debug_state()
	emit_signal("phase_changed", TurnPhase.keys()[phase])
	process_phase()

func roll_first_turn():
	# Randomly decide who goes first
	if randi() % 2 == 0:
		current_turn = "PLAYER"
	else:
		current_turn = "ENEMY"
	print("🎲 First turn roll result:", current_turn)

	update_turn_label("%s Turn" % current_turn.capitalize())

func next_phase():
	match phase:
		TurnPhase.PREBATTLE:
			roll_first_turn()
			if current_turn == "PLAYER":
				phase = TurnPhase.PLAYER_INPUT
			else:
				phase = TurnPhase.ENEMY_INPUT

		TurnPhase.PLAYER_INPUT:
			phase = TurnPhase.PLAYER_RESOLUTION

		TurnPhase.PLAYER_RESOLUTION:			
			current_turn = "ENEMY"
			phase = TurnPhase.ENEMY_INPUT
			update_turn_label("Enemy Turn")

		TurnPhase.ENEMY_INPUT:
			phase = TurnPhase.ENEMY_RESOLUTION

		TurnPhase.ENEMY_RESOLUTION:
			current_turn = "PLAYER"
			phase = TurnPhase.PLAYER_INPUT
			update_turn_label("Player Turn")

		_:
			print("⚠️ Unknown phase transition.")

	_debug_state()
	emit_signal("phase_changed", TurnPhase.keys()[phase])
	process_phase()

# =====================
# Phase Processing
# =====================
func process_phase():
	match phase:
		TurnPhase.PREBATTLE:
			print("⏳ Prebattle warmup: Get ready!")
			beat_count = 0
			if countdown_label:
				countdown_label.text = "Get Ready..."
				show_countdown_label()
			if rhythm_system:
				rhythm_system.connect("beat", Callable(self, "_on_prebattle_beat"), CONNECT_ONE_SHOT)

		TurnPhase.PLAYER_INPUT:
			print("🎵 Player turn: preparing to input a rhythm command...")
			# Wait 1 beat before starting beat bar
			await wait_one_beat()
			$"../CanvasLayer/beatbar".start_phase()
			print("🎵 Beat bar started, player can input now")

		TurnPhase.PLAYER_RESOLUTION:
			$"../CanvasLayer/beatbar".end_phase()
			print("✅ Resolving player action...")
			await get_tree().create_timer(1.0).timeout
			# 1-beat rest before next phase
			await wait_one_beat()
			next_phase()

		TurnPhase.ENEMY_INPUT:
			print("👾 Enemy preparing rhythm sequence...")
			generate_enemy_sequence(4)
			# 1-beat rest before executing enemy sequence
			await wait_one_beat()
			await get_tree().create_timer(2.0).timeout
			next_phase()

		TurnPhase.ENEMY_RESOLUTION:
			print("💥 Enemy executes its action! Player must counter...")
			var dmg = compare_sequences()
			if dmg > 0:
				print("❌ Player failed! Took", dmg, "damage.")
			else:
				print("🛡️ Perfect counter!")
			await get_tree().create_timer(1.0).timeout
			# 1-beat rest before next player input
			await wait_one_beat()
			next_phase()

		_:
			print("⚠️ No logic for this phase.")

# =====================
# Enemy sequence helpers
# =====================
func generate_enemy_sequence(length: int = 4) -> void:
	enemy_sequence.clear()
	for i in range(length):
		enemy_sequence.append(beat_pool[randi() % beat_pool.size()])
	print("👾 Enemy sequence:", enemy_sequence)

func record_player_response(response: Array) -> void:
	player_response = response.duplicate()

func compare_sequences() -> int:
	var damage = 0
	for i in range(min(enemy_sequence.size(), player_response.size())):
		if enemy_sequence[i] != player_response[i]:
			damage += 1
	if player_response.size() < enemy_sequence.size():
		damage += enemy_sequence.size() - player_response.size()
	return damage

# =====================
# UI Animations
# =====================
func show_countdown_label():
	if not countdown_label:
		return
	countdown_label.visible = true
	countdown_label.modulate.a = 0.0
	countdown_label.scale = Vector2.ONE * 2.0  # start big, shrink into place

	var tween = get_tree().create_tween()
	tween.tween_property(countdown_label, "modulate:a", 1.0, 0.2)
	tween.parallel().tween_property(countdown_label, "scale", Vector2.ONE, 0.3).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)

func update_turn_label(text: String):
	if not turn_label:
		return
	turn_label.visible = true
	turn_label.text = text
	turn_label.modulate = Color(1, 1, 1, 1)
	turn_label.scale = Vector2.ONE * 0.5

	var tween = get_tree().create_tween()
	tween.tween_property(turn_label, "scale", Vector2.ONE * 1.2, 0.3).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tween.tween_property(turn_label, "scale", Vector2.ONE, 0.2)

# =====================
# Prebattle Countdown
# =====================
func _on_prebattle_beat(_beat_count: int, _timestamp: int) -> void:
	beat_count += 1

	if beat_count < prebattle_beats:
		var countdown_value = str(prebattle_beats - beat_count)
		print("🎶 Prebattle beat:", countdown_value)
		if countdown_label:
			countdown_label.text = countdown_value
			show_countdown_label()
	else:
		print("🔥 FIGHT!")
		if countdown_label:
			countdown_label.text = "FIGHT!"
			show_countdown_label()
		await get_tree().create_timer(0.5).timeout
		if countdown_label:
			countdown_label.visible = false
		next_phase()
		return

	if rhythm_system:
		rhythm_system.connect("beat", Callable(self, "_on_prebattle_beat"), CONNECT_ONE_SHOT)

# =====================
# Debug Helper
# =====================
func _debug_state():
	print("[TURN MANAGER] Turn: %s | Phase: %s" % [current_turn, TurnPhase.keys()[phase]])
