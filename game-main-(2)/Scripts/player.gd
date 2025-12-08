extends CharacterBody2D
class_name Player

signal hpchange
signal charges_changed  # 🔹 NEW: signal for UI updates (optional)


@onready var sprite: AnimatedSprite2D = $AnimatedSprite2D2
@onready var enemy: Enemy = get_tree().get_first_node_in_group("enemy")
@onready var enemies = get_tree().get_nodes_in_group("enemies")

@export var speed: float = 500.0
@export var jump_velocity: float = -500.0
var gravity = ProjectSettings.get_setting("physics/2d/default_gravity")

@export var max_hp: int = 10
var current_hp: int

# 🔹 NEW: charge system
@export var max_charges: int = 6
var current_charges: int = 0

var is_marching: bool = false
var is_retreating: bool = false
var is_attacking: bool = false
var is_dead: bool = false

var despair_debuff_active: bool = false
var despair_turns_left: int = 0
var despair_attack_cost: int = 2
var despair_heal_cost: int = 3

func apply_despair_debuff(turns: int):
	despair_debuff_active = true
	despair_turns_left = turns
	print("💀 Player afflicted with DESPAIR for", turns, "turns!")


# Effectiveness multiplier (set externally by CommandManager)
var current_command_effectiveness: float = 1.0

func _ready():
	
	var saved_game = SaveLoad.load_game(self, enemies)
	
	if saved_game != null:
		global_position = saved_game.player_position
		current_hp = saved_game.player_hp
		
	else:
		current_hp = max_hp

	current_charges = max_charges / 2  # start at half or set to 0 if you want
	
	emit_signal("charges_changed", current_charges)


func on_cp_reached(enemies:Array):
	SaveLoad.saved_game(self, enemies)

# ==========================
# Command actions
# ==========================
func start_retreat():
	if is_attacking or is_dead:
		return
	print("Character starting to retreat.")
	is_retreating = true
	is_marching = false
	sprite.play("retreat")
	sprite.flip_h = true

	# Wait for a short time before returning to overworld
	var retreat_duration := 1.25  # seconds (adjust as needed)
	await get_tree().create_timer(retreat_duration).timeout

	if battle_scene_handler:
		await battle_scene_handler.return_to_overworld()


func attack():
	if is_attacking or is_dead:
		return
	# 🔹 Check charge cost (2)
	var cost = 4 if despair_debuff_active else 2

	if current_charges < cost:
		print("❌ Not enough charges to attack!")
		return

	current_charges -= cost
	emit_signal("charges_changed", current_charges)


	print("Character attacking.")
	is_attacking = true
	var base_dmg = 4
	var dmg = int(round(base_dmg * current_command_effectiveness))
	dmg = max(0, dmg)

	if enemy and dmg > 0:
		enemy.take_damage(dmg)

	current_command_effectiveness = 1.0
	velocity.x = 0
	sprite.play("attack")

	await sprite.animation_finished
	is_attacking = false
	if not is_dead:
		sprite.play("idle")
		sprite.flip_h = false

func heal(amount: int = 2) -> void:
	if is_dead:
		return
	# 🔹 Check charge cost (3)
	var cost = 5 if despair_debuff_active else 3

	if current_charges < cost:
		print("❌ Not enough charges to heal!")
		return
	current_charges -= cost
	emit_signal("charges_changed", current_charges)


	sprite.play("heal")
	var heal_amount = max(1, int(round(amount * current_command_effectiveness)))
	var new_hp = min(current_hp + heal_amount, max_hp)
	var healed = new_hp - current_hp
	current_hp = new_hp
	if healed > 0:
		print("Player healed for", healed, "HP. Current HP:", current_hp)
		emit_signal("hpchange")
	else:
		print("Heal had no effect (HP is already full).")

	current_command_effectiveness = 1.0

	await sprite.animation_finished
	if not is_dead:
		sprite.play("idle")

# 🔹 NEW: Charge command (gain 1 charge)
func charge_up():
	if is_dead:
		return
	if current_charges >= max_charges:
		print("⚡ Charges full!")
		return

	current_charges = min(current_charges + 1, max_charges)
	print("⚡ Charged! Current charges:", current_charges)
	emit_signal("charges_changed", current_charges)

	sprite.play("charge")  # if you have a charge animation
	await sprite.animation_finished
	if not is_dead:
		sprite.play("idle")

# ==========================
# Physics + Damage
# ==========================
func _physics_process(delta: float) -> void:
	if is_dead:
		return

	if not is_on_floor():
		velocity.y += gravity * delta

	if not is_attacking:
		if is_marching:
			velocity.x = speed
		elif is_retreating:
			velocity.x = -speed
		else:
			velocity.x = 0

	move_and_slide()

signal took_damage  # 🔹 NEW signal

func take_damage(amount: int = 1) -> void:
	if is_dead:
		return

	current_hp = max(current_hp - amount, 0)
	emit_signal("hpchange")
	emit_signal("took_damage")  # 🔹 trigger camera shake
	print("Player took damage! HP:", current_hp)

	is_attacking = false
	is_marching = false
	is_retreating = false
	velocity.x = 0

	sprite.play("hurt")
	await sprite.animation_finished

	if current_hp <= 0:
		die()
	else:
		sprite.play("idle")


func die() -> void:
	if is_dead:
		return
	is_dead = true
	print("Player has been overwhelmed.")
	sprite.play("overwhelm")
	$gameover.play()
	velocity = Vector2.ZERO

	set_physics_process(false)
	set_process(false)

	await sprite.animation_finished
	await $gameover.finished

	TransitionScreen.fade_out()
	await TransitionScreen.on_fade_out_finished

	get_tree().change_scene_to_file("res://Scenes/gameover.tscn")

	TransitionScreen.fade_in()
	await TransitionScreen.on_fade_in_finished

# ==========================
# Command linking
# ==========================


var current_command: String = ""

func get_current_command() -> String:
	return current_command

func execute_command():
	if current_command == "":
		return

	var battle_node = get_tree().get_first_node_in_group("battle")
	if battle_node:
		battle_node.process_command(current_command)
