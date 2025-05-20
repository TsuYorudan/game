extends CharacterBody2D
class_name Player

signal hpchange

@onready var camera: Camera2D = $Camera2D2
@onready var enemy_detector: Area2D = $EnemyDetector
@onready var hurt_receiver: Area2D = $hitbox
@onready var sprite: AnimatedSprite2D = $AnimatedSprite2D2
@onready var main = get_tree().get_root().get_node("gameplay")
@onready var projectile = load("res://attack.tscn")

var base_zoom := Vector2(1, 1)
var zoomed_out := Vector2(1.5, 1.5)
var zoom_speed := 5.0

var enemy_nearby := false

@export var speed: float = 500.0
@export var jump_velocity: float = -500.0
var gravity = ProjectSettings.get_setting("physics/2d/default_gravity")

@export var max_hp: int = 10
var current_hp: int

var is_marching: bool = false
var is_retreating: bool = false
var is_attacking: bool = false
var is_dead: bool = false

func _ready():
	current_hp = max_hp
	enemy_detector.connect("body_entered", Callable(self, "_on_enemy_entered"))
	enemy_detector.connect("body_exited", Callable(self, "_on_enemy_exited"))
	hurt_receiver.connect("area_entered", Callable(self, "_on_hurtbox_entered"))


func start_marching():
	if is_attacking or is_dead:
		return
	print("Character starting to march.")
	is_marching = true
	is_retreating = false
	sprite.play("walk")
	sprite.flip_h = false
	$MarchTimer.start()

func start_retreat():
	if is_attacking or is_dead:
		return
	print("Character starting to retreat.")
	is_retreating = true
	is_marching = false
	sprite.play("retreat")
	sprite.flip_h = true
	$MarchTimer.start()

func stop_moving():
	if is_dead:
		return
	print("Character stopping movement.")
	is_marching = false
	is_retreating = false
	if not is_attacking:
		sprite.play("idle")
		sprite.flip_h = false
	velocity.x = 0

func attack():
	if is_attacking or is_dead:
		return
	print("Character attacking.")
	is_attacking = true
	is_marching = false
	is_retreating = false
	velocity.x = 0
	sprite.play("attack")
	shoot()

	await sprite.animation_finished
	is_attacking = false
	if not is_dead:
		sprite.play("idle")
		sprite.flip_h = false

func shoot():
	var instance = projectile.instantiate()
	instance.spawnPos = global_position
	main.call_deferred("add_child", instance)

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

func _process(delta: float) -> void:
	if is_dead:
		return

	var target_zoom = base_zoom if enemy_nearby else zoomed_out
	var target_offset = Vector2(-150, 130)
	if enemy_nearby:
		target_offset = Vector2(100, 0)
	camera.offset = camera.offset.lerp(target_offset, delta * zoom_speed)
	camera.zoom = camera.zoom.lerp(target_zoom, delta * zoom_speed)

func _on_march_timer_timeout() -> void:
	print("March timer timed out.")
	stop_moving()

func _check_enemies_nearby():
	await get_tree().create_timer(0.1).timeout  # Slight delay to allow cleanup
	enemy_nearby = enemy_detector.get_overlapping_bodies().any(
		func(b): return b.is_in_group("enemies")
	)

func _on_enemy_entered(body):
	if body.is_in_group("enemies"):
		enemy_nearby = true
		if body.has_signal("died"):
			body.connect("died", Callable(self, "_on_enemy_died"), CONNECT_ONE_SHOT)
			
func _on_enemy_died():
	_check_enemies_nearby()

func _on_enemy_exited(body):
	if body.is_in_group("enemies"):
		if not enemy_detector.get_overlapping_bodies().any(
			func(b): return b.is_in_group("enemies")
		):
			enemy_nearby = false

func _on_hurtbox_entered(area: Area2D) -> void:
	if is_dead:
		return

	# Check if the incoming area is from an enemy hurtbox
	if area.name == "hitbox" or area.get_parent().name == "hitbox":
		take_damage()

func take_damage(amount: int = 1) -> void:
	if is_dead:
		return

	current_hp = max(current_hp - amount, 0)
	emit_signal("hpchange")
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
		
func heal(amount: int = 2) -> void:
	if is_dead:
		return
	
	sprite.play("heal")
	var new_hp = min(current_hp + amount, max_hp)
	var healed = new_hp - current_hp
	current_hp = new_hp
	if healed > 0:
		print("Player healed for", healed, "HP. Current HP:", current_hp)
		emit_signal("hpchange")
	else:
		print("Heal had no effect (HP is already full).")
		
	await sprite.animation_finished
	if not is_dead:
		sprite.play("idle")
	



func die() -> void:
	if is_dead:
		return
	is_dead = true
	print("Player has been overwhelmed.")
	sprite.play("overwhelm")
	velocity = Vector2.ZERO
	set_physics_process(false)
	set_process(false)

	await sprite.animation_finished

	# Fade to black and go to main menu
	TransitionScreen.fade_out()           # Start fading to black

	# Wait until fade to black is done
	await TransitionScreen.on_fade_out_finished
	get_tree().change_scene_to_file("res://Scenes/main_menu.tscn")
	TransitionScreen.fade_in()
	await TransitionScreen.on_fade_in_finished 
