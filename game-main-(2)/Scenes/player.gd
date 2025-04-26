extends CharacterBody2D

@export var speed: float = 200.0
@export var jump_velocity: float = -300.0
var gravity = ProjectSettings.get_setting("physics/2d/default_gravity")

func _physics_process(delta):
	if not is_on_floor():
		velocity.y += gravity * delta
	
	var direction = Vector2.ZERO

	if Input.is_action_pressed("right"):
		direction.x += 1.5
	if Input.is_action_pressed("left"):
		direction.x -= 1.5
	if Input.is_action_pressed("jump") and is_on_floor():
		velocity.y = jump_velocity
	if Input.is_action_just_pressed("pata"):
		print("pata")
	if Input.is_action_just_pressed("pon"):
		print("pon")
	if Input.is_action_just_pressed("don"):
		print("don")
	if Input.is_action_just_pressed("chaka"):
		print("chaka")
	velocity.x = direction.x * speed
	move_and_slide()
