extends CharacterBody2D

@export var SPEED := 100.0
@export var ATTACK_RANGE := 40.0
@export var DISSOLVE_TIME := 1.2

@onready var sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var detector: Area2D = $Area2D

var player: Node2D = null
var state: String = "idle"
var is_dead := false

func _ready() -> void:
	detector.body_entered.connect(_on_body_entered)

func _physics_process(delta: float) -> void:
	if is_dead:
		return

	match state:
		"idle":
			sprite.play("idle")
			velocity = Vector2.ZERO
			move_and_slide()
		"walk":
			if player:
				var to_player = player.global_position - global_position
				if to_player.length() > ATTACK_RANGE:
					var dir = to_player.normalized()
					velocity = dir * SPEED
					sprite.flip_h = velocity.x < 0
					sprite.play("walk")
				else:
					velocity = Vector2.ZERO
					state = "attack"
			move_and_slide()
		"attack":
			velocity = Vector2.ZERO
			move_and_slide()
			sprite.play("attack")
			await sprite.animation_finished
			state = "idle"
		"hurt":
			velocity = Vector2.ZERO
			move_and_slide()
			sprite.play("hurt")
			await sprite.animation_finished
			state = "idle"
		"dissolve":
			is_dead = true
			velocity = Vector2.ZERO
			move_and_slide()
			sprite.play("dissolve")
			await sprite.animation_finished
			queue_free()

func _on_body_entered(body: Node) -> void:
	if body.name == "Player":
		player = body
		state = "walk"

func take_damage() -> void:
	if is_dead:
		return
	state = "hurt"

func die() -> void:
	if is_dead:
		return
	state = "dissolve"
