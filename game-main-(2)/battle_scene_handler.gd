extends Node

@export var overworld_scene_path: String = "res://overworld.tscn"
@export var player_group_name: String = "player_top"

var saved_player_position: Vector2 = Vector2.ZERO

# Call this from TurnManager when battle ends
func return_to_overworld():
	# Find the player in the current overworld scene (before loading)
	var overworld_player = get_tree().get_first_node_in_group(player_group_name)
	if overworld_player:
		saved_player_position = overworld_player.global_position
		if "can_move" in overworld_player:
			overworld_player.can_move = false

	# Fade out
	if TransitionScreen:
		await TransitionScreen.fade_out_and_wait()

	# Change scene to overworld
	if ResourceLoader.exists(overworld_scene_path):
		get_tree().change_scene_to_file(overworld_scene_path)
	else:
		push_error("❌ Overworld scene not found: %s" % overworld_scene_path)
		return

	# Wait one frame to ensure scene is loaded
	await get_tree().process_frame
	await get_tree().process_frame

	# Restore player in the new overworld scene
	overworld_player = get_tree().get_first_node_in_group(player_group_name)
	if overworld_player:
		overworld_player.global_position = saved_player_position
		if "can_move" in overworld_player:
			overworld_player.can_move = true
	else:
		push_warning("⚠️ Player node not found in overworld scene.")
