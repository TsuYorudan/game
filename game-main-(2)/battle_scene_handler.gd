extends Node

@export var overworld_scene_path: String = "res://overworld.tscn"
@export var player_group_name: String = "player_top"

var saved_player_position: Vector2 = Vector2.ZERO

func save_overworld_player_position():
	var overworld_player = get_tree().get_first_node_in_group(player_group_name)
	if overworld_player:
		saved_player_position = overworld_player.global_position
		print("💾 Saved overworld player position:", saved_player_position)

func return_to_overworld() -> void:
	print("🌍 Returning to overworld...")

	# Fade out
	if TransitionScreen:
		await TransitionScreen.fade_out_and_wait()

	# Change to overworld scene
	if ResourceLoader.exists(overworld_scene_path):
		get_tree().change_scene_to_file(overworld_scene_path)
	else:
		push_error("❌ Overworld scene not found at: %s" % overworld_scene_path)
		return

	# Wait for scene to load
	await get_tree().process_frame
	await get_tree().process_frame

	# Restore player position
	var overworld_player = get_tree().get_first_node_in_group(player_group_name)
	if overworld_player:
		overworld_player.global_position = saved_player_position
		if "can_move" in overworld_player:
			overworld_player.can_move = true
		print("✅ Restored player position:", saved_player_position)
	else:
		push_warning("⚠️ Could not find player in overworld scene.")
