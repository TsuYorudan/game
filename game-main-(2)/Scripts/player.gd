extends CharacterBody2D

@onready var camera: Camera2D = $Camera2D2
@onready var enemy_detector: Area2D = $EnemyDetector
@onready var main = get_tree().get_root().get_node("gameplay")
@onready var projectile = load("res://attack.tscn")

var base_zoom := Vector2(1, 1)
var zoomed_out := Vector2(1.5, 1.5)  # Adjust for how far out you want
var zoom_speed := 5.0

var enemy_nearby := false

@export var speed: float = 500.0
@export var jump_velocity: float = -500.0
var gravity = ProjectSettings.get_setting("physics/2d/default_gravity")

var is_marching: bool = false
var is_retreating: bool = false
var is_attacking: bool = false

@onready var sprite: AnimatedSprite2D = $AnimatedSprite2D2

func start_marching():
	if is_attacking:
		return
	print("Character starting to march.")
	is_marching = true
	is_retreating = false
	sprite.play("walk")
	sprite.flip_h = false
	$MarchTimer.start()

func start_retreat():
	if is_attacking:
		return
	print("Character starting to retreat.")
	is_retreating = true
	is_marching = false
	sprite.play("retreat")
	sprite.flip_h = true
	$MarchTimer.start()

func stop_moving():
	print("Character stopping movement.")
	is_marching = false
	is_retreating = false
	if not is_attacking:
		sprite.play("idle")
		sprite.flip_h = false
	velocity.x = 0

func attack():
	if is_attacking:
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
	sprite.play("idle")
	sprite.flip_h = false

func shoot():
	var instance = projectile.instantiate()
	instance.spawnPos = global_position  # set this BEFORE adding to tree
	main.call_deferred("add_child", instance)


func _physics_process(delta: float) -> void:
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

func _on_march_timer_timeout() -> void:
	print("March timer timed out.")
	stop_moving()
	
func _ready():
	enemy_detector.connect("body_entered", Callable(self, "_on_enemy_entered"))
	enemy_detector.connect("body_exited", Callable(self, "_on_enemy_exited"))

func _on_enemy_entered(body):
	if body.is_in_group("enemies"):
		enemy_nearby = true

func _on_enemy_exited(body):
	if body.is_in_group("enemies"):
		# If no more enemies inside the area
		if not enemy_detector.get_overlapping_bodies().any(
			func(b): return b.is_in_group("enemies")
		):
			enemy_nearby = false

func _process(delta):
	var target_zoom = base_zoom if enemy_nearby else zoomed_out
	var target_offset = Vector2(-150, 130)
	if enemy_nearby:
		target_offset = Vector2(100, 0)
	camera.offset = camera.offset.lerp(target_offset, delta * zoom_speed)
	camera.zoom = camera.zoom.lerp(target_zoom, delta * zoom_speed)
