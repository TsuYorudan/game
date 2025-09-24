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

# ================
# Core Turn Control
# ================

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
			# after prebattle, roll who starts
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

# ================
# Phase Processing
# ================

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
			print("🎵 Waiting for player to input a rhythm command...")

		TurnPhase.PLAYER_RESOLUTION:
			print("✅ Resolving player action...")
			await get_tree().create_timer(1.0).timeout
			next_phase()

		TurnPhase.ENEMY_INPUT:
			print("👾 Enemy preparing rhythm sequence...")
			await get_tree().create_timer(1.0).timeout
			next_phase()

		TurnPhase.ENEMY_RESOLUTION:
			print("💥 Enemy executes its action! Player may counter/block...")
			await get_tree().create_timer(1.0).timeout
			next_phase()

		_:
			print("⚠️ No logic for this phase.")

# ================
# UI Animations
# ================

func show_countdown_label():
	if not countdown_label:
		return
	countdown_label.visible = true
	countdown_label.modulate.a = 0.0
	countdown_label.scale = Vector2.ONE * 2.0  # start big, shrink into place

	var tween = get_tree().create_tween()
	tween.tween_property(countdown_label, "modulate:a", 1.0, 0.2) # fade in
	tween.parallel().tween_property(countdown_label, "scale", Vector2.ONE, 0.3).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)

func update_turn_label(text: String):
	if not turn_label:
		return
	turn_label.visible = true
	turn_label.text = text
	turn_label.modulate = Color(1, 1, 1, 1) # always visible
	turn_label.scale = Vector2.ONE * 0.5

	var tween = get_tree().create_tween()
	tween.tween_property(turn_label, "scale", Vector2.ONE * 1.2, 0.3).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tween.tween_property(turn_label, "scale", Vector2.ONE, 0.2)

# ================
# Prebattle Countdown
# ================

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

	# Keep listening until we finish 4 beats
	if rhythm_system:
		rhythm_system.connect("beat", Callable(self, "_on_prebattle_beat"), CONNECT_ONE_SHOT)

# ================
# Debug Helper
# ================

func _debug_state():
	print("[TURN MANAGER] Turn: %s | Phase: %s" % [current_turn, TurnPhase.keys()[phase]])
