extends Node
enum TurnPhase { PREBATTLE, PLAYER_INPUT, PLAYER_RESOLUTION, ENEMY_INPUT, ENEMY_RESOLUTION, BATTLE_END, END }

var current_turn: String = "PLAYER"
var phase: TurnPhase = TurnPhase.PREBATTLE

signal phase_changed(phase: String)

@export var prebattle_beats: int = 3
var beat_count: int = 0

@onready var player: Player = get_tree().get_first_node_in_group("player")
@onready var enemy: Enemy = get_tree().get_first_node_in_group("enemy")
@onready var rhythm_system: Node = $"../RhythmSystem"
@onready var countdown_label: Label = $"../CanvasLayer/Control/CountdownLabel"
@onready var turn_label: Label = $"../CanvasLayer/Control/TurnLabel"

var reverse_challenge: bool = false
@onready var reverse_label: Label = $"../CanvasLayer/Control/ReverseLabel"


var player_response: Array = []

signal _beat_rest_done

func wait_one_beat() -> void:
	if rhythm_system:
		var connection: Callable = Callable(self, "_on_rest_beat")
		rhythm_system.connect("beat", connection, CONNECT_ONE_SHOT)
		await self._beat_rest_done

func _on_rest_beat(_beat_count: int, _timestamp: int) -> void:
	emit_signal("_beat_rest_done")

func _ready():
	if not is_in_group("turn_manager"):
		add_to_group("turn_manager")
	if countdown_label:
		countdown_label.visible = false
	if turn_label:
		turn_label.visible = true

	# Play fade-in transition when battle starts
	if TransitionScreen:
		await TransitionScreen.fade_in()

	start_battle()


func start_battle():
	phase = TurnPhase.PREBATTLE
	_debug_state()
	emit_signal("phase_changed", TurnPhase.keys()[phase])
	await process_phase()

func roll_first_turn():
	if randi() % 2 == 0:
		current_turn = "PLAYER"
	else:
		current_turn = "ENEMY"
	update_turn_label("%s Turn" % current_turn.capitalize())

	# 🕒 If enemy starts first, wait one beat before proceeding
	if current_turn == "ENEMY":
		print("🕐 Enemy rolled first — waiting one beat before starting...")
		await wait_one_beat()


func next_phase():
	# Check for death
	if (player and player.is_dead):
		if reverse_label:
			reverse_label.visible = false
		print("⚡ Battle ended. Disabling everything.")
		if rhythm_system:
			rhythm_system.stop_rhythm()
		var beatbar = get_tree().get_first_node_in_group("beatbar")
		if beatbar:
			beatbar.end_phase()
			beatbar.set_process(false)
			beatbar.visible = false
				
	if(enemy and enemy.is_dead):
		phase = TurnPhase.BATTLE_END
	else:
		match phase:
			TurnPhase.PREBATTLE:
				roll_first_turn()
				phase = TurnPhase.PLAYER_INPUT if current_turn == "PLAYER" else TurnPhase.ENEMY_INPUT
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
	await process_phase()

func record_player_response(response: Array) -> void:
	player_response = response.duplicate()
	if reverse_challenge:
		player_response.reverse()


func process_phase() -> void:
	match phase:
		TurnPhase.PREBATTLE:
			beat_count = 0
			if countdown_label:
				countdown_label.text = "Get Ready..."
				show_countdown_label()
			if rhythm_system:
				rhythm_system.connect("beat", Callable(self, "_on_prebattle_beat"), CONNECT_ONE_SHOT)

		TurnPhase.PLAYER_INPUT:
			$"../CanvasLayer/timeline".set_phase(0)
			$"../CanvasLayer/beatbar".is_enemy_turn = false
			$"../CanvasLayer/beatbar".start_phase()
			print("🎵 Player can input now")

		TurnPhase.PLAYER_RESOLUTION:
			$"../CanvasLayer/timeline".set_phase(1)
			$"../CanvasLayer/beatbar".end_phase()
			# Check for charges before executing commands
			if player_response.size() > 0:
				for cmd in player_response:
					match cmd:
						"attack":
							if player.current_charges >= 2:
								player.current_charges -= 2
								player.execute_command()
							else:
								print("❌ Not enough charges for attack")
						"heal":
							if player.current_charges >= 3:
								player.current_charges -= 3
								player.execute_command()
							else:
								print("❌ Not enough charges for heal")
						"charge":
							player.charge_up()
						"retreat":
							player.execute_command()
			for i in range(4):
				await wait_one_beat()
			next_phase()

		TurnPhase.ENEMY_INPUT:
			$"../CanvasLayer/timeline".set_phase(2)
			print("👾 Enemy turn...")
			update_turn_label("Enemy Turn")
			if enemy:
				$"../CanvasLayer/beatbar".is_enemy_turn = true
				$"../CanvasLayer/beatbar".start_phase()
				enemy.generate_sequence(4)
			reverse_challenge = randf() < 0.25

			if reverse_label:
				if reverse_challenge:
					reverse_label.visible = true
					reverse_label.modulate = Color(1, 0.3, 0.3, 1)
					reverse_label.scale = Vector2.ONE * 0.8
					reverse_label.text = "REVERSE!"  # just to be safe
					await get_tree().process_frame  # ensures label actually updates next frame

					var tween = get_tree().create_tween()
					tween.tween_property(reverse_label, "scale", Vector2.ONE * 1.3, 0.25).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
					tween.tween_property(reverse_label, "scale", Vector2.ONE, 0.25)
				else:
					reverse_label.visible = false
				await enemy.play_sequence(rhythm_system)
				
			if reverse_label and reverse_challenge:
				reverse_label.visible = false
				# 🔄 25% chance next player phase requires reversed input
			next_phase()

		TurnPhase.ENEMY_RESOLUTION:
			$"../CanvasLayer/timeline".set_phase(3)
			update_turn_label("COUNTER")
			$"../CanvasLayer/beatbar".end_phase()
			$"../CanvasLayer/beatbar".is_enemy_turn = false
			$"../CanvasLayer/beatbar".start_phase()
			for i in range(4):
				await wait_one_beat()
			$"../CanvasLayer/beatbar".end_phase()
			$"../CanvasLayer/timeline".set_phase(4)

			# Resolve enemy attack and award charge on successful counter
			if enemy:
				var result = await enemy.resolve_attack(player_response)
				var damage = result.damage if "damage" in result else result
				var countered = result.countered if "countered" in result else false

				if damage > 0 and player and not player.is_dead:
					player.take_damage(damage)
				elif countered:
					player.charge_up()
					print("✅ Counter successful, gained 1 charge!")

			for i in range(3):
				await wait_one_beat()
			next_phase()

		TurnPhase.BATTLE_END:
			if reverse_label:
				reverse_label.visible = false
			print("⚡ Battle ended. Disabling everything.")
			if rhythm_system:
				rhythm_system.stop_rhythm()
			var beatbar = get_tree().get_first_node_in_group("beatbar")
			if beatbar:
				beatbar.end_phase()
				beatbar.set_process(false)
				beatbar.visible = false
				
			if enemy and enemy.sprite and enemy.is_dead:
				while enemy.sprite.animation != "dissolve":
					await get_tree().process_frame

			print("🏆 Battle finished.")

			# ✅ Go back to overworld with previous position
			if BattleSceneHandler:
				await battle_scene_handler.return_to_overworld()

			phase = TurnPhase.END

		_:
			print("⚠️ No logic for this phase.")

# UI Helpers
func show_countdown_label():
	if not countdown_label:
		return
	countdown_label.visible = true
	countdown_label.modulate.a = 0.0
	countdown_label.scale = Vector2.ONE * 2.0
	var tween = get_tree().create_tween()
	tween.tween_property(countdown_label, "modulate:a", 1.0, 0.2)
	tween.parallel().tween_property(countdown_label, "scale", Vector2.ONE, 0.3).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)

func update_turn_label(text: String):
	if not turn_label:
		return
	turn_label.visible = true
	turn_label.text = text
	turn_label.modulate = Color(1,1,1,1)
	turn_label.scale = Vector2.ONE * 0.5
	var tween = get_tree().create_tween()
	tween.tween_property(turn_label, "scale", Vector2.ONE * 1.2, 0.3).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tween.tween_property(turn_label, "scale", Vector2.ONE, 0.2)

func _on_prebattle_beat(_beat_count: int, _timestamp: int) -> void:
	beat_count += 1
	if beat_count < prebattle_beats:
		if countdown_label:
			countdown_label.text = str(prebattle_beats - beat_count)
			show_countdown_label()
	else:
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

func _debug_state():
	print("[TURN MANAGER] Turn: %s | Phase: %s" % [current_turn, TurnPhase.keys()[phase]])
