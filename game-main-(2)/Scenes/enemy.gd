extends CharacterBody2D

signal died

@export var SPEED := 100.0
@export var DISSOLVE_TIME := 1.2
@export var MAX_HP := 3

@onready var sprite: AnimatedSprite2D = $AnimatedSprite2D

var player: Node2D = null
var state: String = "idle"
var is_dead := false
var hp: int

func _ready() -> void:
	hp = MAX_HP
	print("[DEBUG] Enemy ready, HP =", hp)

func _physics_process(delta: float) -> void:
	if is_dead:
		return

	match state:
		"idle":
			sprite.play("idle")
			velocity = Vector2.ZERO
			move_and_slide()

		"walk":
			var to_player = player.global_position - global_position
			var dir = to_player.normalized()
			velocity = dir * SPEED
			sprite.play("walk")
			move_and_slide()

		"attack":
			velocity = Vector2.ZERO
			move_and_slide()

		"hurt":
			velocity = Vector2.ZERO
			move_and_slide()
			sprite.play("hurt")
			await sprite.animation_finished
			if hp > 0:
				state = "walk"
			else:
				die()

		"dissolve":
			is_dead = true
			emit_signal("died")
			velocity = Vector2.ZERO
			move_and_slide()
			sprite.play("dissolve")
			await sprite.animation_finished
			free()


func take_damage() -> void:
	if is_dead:
		return
	hp -= 1
	print("[DEBUG] Enemy took damage! HP =", hp)
	if hp > 0:
		state = "hurt"
	else:
		die()

func die() -> void:
	if is_dead:
		return
	print("[DEBUG] Enemy died.")
	state = "dissolve"
