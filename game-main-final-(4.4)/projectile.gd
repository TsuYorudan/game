extends CharacterBody2D

@export var MAX_SPEED: float = 300
var spawnPos: Vector2

@onready var anim: AnimatedSprite2D = $AnimatedSprite2D
@onready var hit_timer := Timer.new()

var current_speed: float = 0.0
var time_alive: float = 0.0
var ease_duration: float = 1.0
var has_dissipated := false

func _ready():
	add_to_group("projectile")  # So enemy can identify this
	global_position = spawnPos

	add_child(hit_timer)
	hit_timer.wait_time = 2.0
	hit_timer.one_shot = true
	hit_timer.connect("timeout", _on_timeout)
	hit_timer.start()

	anim.play("shoot")

func _physics_process(delta: float) -> void:
	if has_dissipated:
		return

	time_alive += delta
	var t: float = clamp(time_alive / ease_duration, 0.0, 1.0)
	var eased: float = t * t * t

	current_speed = lerp(0.0, MAX_SPEED, eased)
	velocity = Vector2(current_speed, 0)
	move_and_slide()

func _on_timeout() -> void:
	start_dissipate()

func _on_hit_enemy() -> void:
	print("[DEBUG] Projectile triggered _on_hit_enemy()")
	start_dissipate()

func start_dissipate():
	if has_dissipated:
		return
	has_dissipated = true
	velocity = Vector2.ZERO
	anim.play("dissipate")
	await anim.animation_finished
	queue_free()
