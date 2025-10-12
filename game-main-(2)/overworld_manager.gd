extends Node
class_name BattleSceneHandler

@export var overworld_scene_path: String = "res://overworld.tscn"
@export var player_group_name: String = "player_top"

# Store position before leaving battle
var saved_player_position: Vector2 = Vector2.ZERO

func _ready():
	TransitionScreen.fade_in()

# Call this to end battle and return to overworld
func return_to_overworld(player: Node) -> void:
	if not player:
		push_error("No player node provided!")
		return

	# Save current player position
	saved_player_position = player.global_position

	# Disable player movement during transition
	if "can_move" in player:
		player.can_move = false

	# Play fade out
	if TransitionScreen:
		await TransitionScreen.fade_out_and_wait()

	# Change scene to overworld
	if ResourceLoader.exists(overworld_scene_path):
		get_tree().change_scene_to_file(overworld_scene_path)
	else:
		push_error("❌ Overworld scene not found at: %s" % overworld_scene_path)
		return

	# Wait one frame for scene to load
	await get_tree().process_frame

	# Find player in overworld and restore position
	var overworld_player = get_tree().get_first_node_in_group(player_group_name)
	if overworld_player:
		overworld_player.global_position = saved_player_position
		if "can_move" in overworld_player:
			overworld_player.can_move = true
