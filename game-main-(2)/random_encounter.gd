extends Node
class_name RandomEncounter

@export var player: NodePath
@export var battle_scene_path: String = "res://Scenes/battle.tscn"
@export var encounter_chance: float = 0.02
@export var check_interval: float = 1.0
@export var min_steps_before_encounter: int = 5

var _player_ref: CharacterBody2D
var _steps_since_last_encounter: int = 0
var _rng := RandomNumberGenerator.new()

func _ready():
	if player != NodePath(""):
		_player_ref = get_node_or_null(player)
		if not _player_ref:
			push_error("❌ Player node not found at path: %s" % player)
	else:
		push_warning("⚠️ No player assigned to RandomEncounter.")

	_rng.randomize()

	# Timer to check for encounters
	var timer = Timer.new()
	timer.name = "EncounterTimer"
	timer.wait_time = check_interval
	timer.autostart = true
	timer.one_shot = false
	add_child(timer)
	timer.timeout.connect(_on_check_encounter)


func _on_check_encounter() -> void:
	if not _player_ref:
		return

	# Count steps when the player is moving
	if _player_ref.velocity.length() > 0:
		_steps_since_last_encounter += 1

		if _steps_since_last_encounter >= min_steps_before_encounter:
			if _rng.randf() < encounter_chance:
				await start_battle()


func start_battle() -> void:
	if not _player_ref:
		return

	print("⚔️ Random Encounter Triggered!")
	_steps_since_last_encounter = 0

	# ✅ Save overworld position globally before leaving
	if BattleSceneHandler:
		battle_scene_handler.saved_player_position = _player_ref.global_position
		print("💾 Saved overworld position:", battle_scene_handler.saved_player_position)

	# Stop player movement
	if "can_move" in _player_ref:
		_player_ref.can_move = false

	# Fade out transition (optional)
	if TransitionScreen:
		await TransitionScreen.fade_out_and_wait()
	elif ZoomTransition:
		await zoom_transition.play_transition()

	# Load battle scene
	if ResourceLoader.exists(battle_scene_path):
		get_tree().change_scene_to_file(battle_scene_path)
	else:
		push_error("❌ Battle scene not found at: %s" % battle_scene_path)
