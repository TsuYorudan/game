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

# Camera shake variables
var camera_shake_strength := 55.0
var camera_shake_duration := 0.3
var camera_shake_timer := 0.0
var rng := RandomNumberGenerator.new()

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
	# Check if enemies are nearby
	enemy_nearby = enemy_detector.get_overlapping_bodies().any(
		func(b): return b.is_in_group("enemies")
	)

	# Determine zoom and offset
	var target_zoom = base_zoom if enemy_nearby or is_dead else zoomed_out
	var target_offset = Vector2.ZERO
	if is_dead:
		target_offset = Vector2.ZERO
	elif enemy_nearby:
		target_offset = Vector2(100, 0)
	else:
		target_offset = Vector2(-150, 130)

	# Camera shake logic
	if camera_shake_timer > 0:
		camera_shake_timer -= delta
		var shake_offset = Vector2(
			rng.randf_range(-camera_shake_strength, camera_shake_strength),
			rng.randf_range(-camera_shake_strength, camera_shake_strength)
		)
		camera.offset = camera.offset.lerp(target_offset + shake_offset, delta * zoom_speed)
	else:
		camera.offset = camera.offset.lerp(target_offset, delta * zoom_speed)

	camera.zoom = camera.zoom.lerp(target_zoom, delta * zoom_speed)

func _on_march_timer_timeout() -> void:
	print("March timer timed out.")
	stop_moving()

func _on_hurtbox_entered(area: Area2D) -> void:
	if is_dead:
		return

	if area.name == "hitbox" or area.get_parent().name == "hitbox":
		take_damage()

func take_damage(amount: int = 1) -> void:
	if is_dead:
		return

	current_hp = max(current_hp - amount, 0)
	emit_signal("hpchange")
	print("Player took damage! HP:", current_hp)

	# Trigger camera shake
	camera_shake_timer = camera_shake_duration

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
	$gameover.play()
	velocity = Vector2.ZERO

	# Camera zoom-in and offset transition
	var zoom_duration := 0.3
	var zoom_timer := 0.0
	var start_zoom = camera.zoom
	var end_zoom = Vector2(3.0, 3.0)  # Strong zoom-IN
	var start_offset = camera.offset
	var end_offset = Vector2(-380, 150)  # Upward focus (adjust as needed)

	while zoom_timer < zoom_duration:
		var t = zoom_timer / zoom_duration
		camera.zoom = start_zoom.lerp(end_zoom, t)
		camera.offset = start_offset.lerp(end_offset, t)
		zoom_timer += get_process_delta_time()
		await get_tree().process_frame

	# Ensure final values are set
	camera.zoom = end_zoom
	camera.offset = end_offset

	# Stop input
	set_physics_process(false)
	set_process(false)

	await sprite.animation_finished
	await $gameover.finished

	TransitionScreen.fade_out()
	await TransitionScreen.on_fade_out_finished

	get_tree().change_scene_to_file("res://Scenes/gameplay.tscn")

	TransitionScreen.fade_in()
	await TransitionScreen.on_fade_in_finished
