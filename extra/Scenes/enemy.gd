extends CharacterBody2D

signal died

@export var SPEED := 100.0
@export var DISSOLVE_TIME := 1.2
@export var MAX_HP := 3

@onready var sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var detector: Area2D = $Area2D
@onready var attack_area: Area2D = $Area2D2
@onready var hitbox: Area2D = $hitbox  # For *attacking* the player
@onready var hurtbox: Area2D = $hurtbox  # For *receiving* damage
@onready var attack_repeat_timer: Timer = $Timer

var player: Node2D = null
var state: String = "idle"
var is_dead := false
var hp: int

func _ready() -> void:
	hp = MAX_HP
	detector.body_entered.connect(_on_body_entered)
	attack_area.body_entered.connect(_on_attack_area_entered)
	attack_area.body_exited.connect(_on_attack_area_exited)
	attack_repeat_timer.timeout.connect(_on_attack_repeat_timeout)
	hitbox.monitoring = false
	hurtbox.monitoring = true
	hurtbox.connect("area_entered", _on_hurtbox_area_entered)
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

func _on_body_entered(body: Node) -> void:
	if body.is_in_group("player"):
		player = body
		state = "walk"

func _on_attack_area_entered(body: Node) -> void:
	if body.is_in_group("player"):
		player = body
		if state != "attack":
			state = "attack"
			attack_repeat_timer.start()

func _on_attack_area_exited(body: Node) -> void:
	if body == player and not is_dead:
		attack_repeat_timer.stop()
		state = "walk"

func _on_attack_repeat_timeout() -> void:
	if state == "attack" and not is_dead:
		hitbox.monitoring = true
		sprite.play("attack")
		await sprite.animation_finished
		sprite.play("idle")
		hitbox.monitoring = false

func _on_hurtbox_area_entered(area: Area2D) -> void:
	if is_dead:
		return

	# DEBUG OUTPUT
	print("[DEBUG] Hurtbox touched by:", area.name)

	if area.name == "hitbox" or area.get_parent().name == "hitbox":
		print("[DEBUG] Projectile hit confirmed!")
		take_damage()

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
