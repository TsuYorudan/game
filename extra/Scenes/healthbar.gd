extends ProgressBar

@export var player: Node  # No type checking

func _ready():
	if player:
		player.connect("hpchange", Callable(self, "_on_player_hpchange"))
		await player.ready  # Ensure the player is initialized
		update_bar()
	else:
		print("No player assigned!")


func update_bar():
	value = player.current_hp * 100.0 / player.max_hp

func _on_player_hpchange():
	update_bar()
