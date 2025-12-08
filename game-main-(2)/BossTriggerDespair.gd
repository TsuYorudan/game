extends Area2D

@export var boss_scene_path: String = "res://Scenes/DespairBoss.tscn"
@export var player_group_name: String = "player_top"
@export var single_use: bool = true

var triggered: bool = false

func _ready():
	connect("body_entered", Callable(self, "_on_body_entered"))

func _on_body_entered(body: Node) -> void:
	if triggered and single_use:
		return

	if body.is_in_group(player_group_name):
		triggered = true
		open_boss_scene()

func open_boss_scene() -> void:
	# Optional: save player position if you want to return later
	var player_node = get_tree().get_first_node_in_group(player_group_name)
	if player_node:
		battle_scene_handler.saved_player_position = player_node.global_position
		if "can_move" in player_node:
			player_node.can_move = false

	# Optional: fade out screen
	if TransitionScreen:
		await TransitionScreen.fade_out_and_wait()

	# Change scene directly to the boss
	if ResourceLoader.exists(boss_scene_path):
		get_tree().change_scene_to_file(boss_scene_path)
	else:
		push_error("❌ Boss scene not found: %s" % boss_scene_path)
