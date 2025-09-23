extends Node

# Turn phases
enum TurnPhase { START, PLAYER_INPUT, PLAYER_RESOLUTION, ENEMY_INPUT, ENEMY_RESOLUTION, END }

var current_turn: String = "PLAYER"
var phase: TurnPhase = TurnPhase.START

func _ready():
	# Register so CommandManager and others can find this node
	if not is_in_group("turn_manager"):
		add_to_group("turn_manager")

	# Start the battle loop
	start_battle()

# ================
# Core Turn Control
# ================

func start_battle():
	current_turn = "PLAYER"
	phase = TurnPhase.PLAYER_INPUT
	_debug_state()
	process_phase()

func next_phase():
	match phase:
		TurnPhase.PLAYER_INPUT:
			phase = TurnPhase.PLAYER_RESOLUTION

		TurnPhase.PLAYER_RESOLUTION:
			current_turn = "ENEMY"
			phase = TurnPhase.ENEMY_INPUT

		TurnPhase.ENEMY_INPUT:
			phase = TurnPhase.ENEMY_RESOLUTION

		TurnPhase.ENEMY_RESOLUTION:
			current_turn = "PLAYER"
			phase = TurnPhase.PLAYER_INPUT

		_:
			print("⚠️ Unknown phase transition.")

	_debug_state()
	process_phase()

# ================
# Phase Processing
# ================

func process_phase():
	match phase:
		TurnPhase.PLAYER_INPUT:
			print("🎵 Waiting for player to input a rhythm command...")

		TurnPhase.PLAYER_RESOLUTION:
			print("✅ Resolving player action...")
			await get_tree().create_timer(1.0).timeout
			next_phase()

		TurnPhase.ENEMY_INPUT:
			print("👾 Enemy preparing rhythm sequence...")
			# Here you can generate an enemy "command sequence" to show to player
			await get_tree().create_timer(1.0).timeout
			next_phase()

		TurnPhase.ENEMY_RESOLUTION:
			print("💥 Enemy executes its action! Player may counter/block...")
			await get_tree().create_timer(1.0).timeout
			next_phase()

		_:
			print("⚠️ No logic for this phase.")

# ================
# Debug Helper
# ================

func _debug_state():
	print("[TURN MANAGER] Turn: %s | Phase: %s" % [current_turn, TurnPhase.keys()[phase]])
