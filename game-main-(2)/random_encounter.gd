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

var saved_position: Vector2  # save player overworld position

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

	if _player_ref.velocity.length() > 0:
		_steps_since_last_encounter += 1

		if _steps_since_last_encounter >= min_steps_before_encounter:
			if _rng.randf() < encounter_chance:
				start_battle()


func start_battle() -> void:
	if not _player_ref:
		return

	print("⚔️ Random Encounter Triggered!")
	_steps_since_last_encounter = 0

	# Save overworld position
	saved_position = _player_ref.global_position

	# Stop player movement
	_player_ref.can_move = false

	# Fade out
	if ZoomTransition:
		await zoom_transition.play_transition()  # await the zoom/fade animation

	# Load battle scene
	if ResourceLoader.exists(battle_scene_path):
		get_tree().change_scene_to_file(battle_scene_path)
	else:
		push_error("❌ Battle scene not found at: %s" % battle_scene_path)
