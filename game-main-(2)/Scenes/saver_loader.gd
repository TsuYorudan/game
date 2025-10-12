extends Node
class_name SaverLoader

const path = "user://SaveGame.tres"

func save_game(player : Node, enemies : Array):
	var saved_game:SaveGame = SaveGame.new()
	
	saved_game.player_hp = player.current_hp
	saved_game.player_position = player.global_position
	
	for enemy in enemies:
		if is_instance_valid(enemy):
			var e_data:= EnemyData.new()
			e_data.enemy_id = enemy.e_id 
			e_data.enemy_pos= enemy.global_position
			e_data.enemy_hp = enemy.hp
			e_data.is_dead = enemy.is_dead
			saved_game.enemies.append(e_data)
	
	var err = ResourceSaver.save(saved_game, path)
	if err != OK:
		print("Failed to save game! Error code:", err)
	
func load_game(player: Node, enemies : Array):
	var saved_game:SaveGame = ResourceLoader.load(path)
	
	if saved_game == null:
		print("there's an error")
		return
		
	var enemies_to_remove := []

	for saved_enemy in saved_game.enemies:
		for enemy in enemies:
			if is_instance_valid(enemy) and enemy.e_id == saved_enemy.id:
				enemy.global_position = saved_enemy.position
				enemy.hp = saved_enemy.health
				enemy.is_dead = saved_enemy.is_dead
				if enemy.is_dead:
					enemies_to_remove.append(enemy)
	for e in enemies_to_remove:
		if is_instance_valid(e):
			e.queue_free()
			
	return saved_game
	
	
func reset_game():
	if FileAccess.file_exists(SaveLoad.path):
		DirAccess.remove_absolute(SaveLoad.path)
		
func existing_file() -> bool:
	return FileAccess.file_exists(path)
