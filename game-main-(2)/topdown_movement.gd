extends CharacterBody2D
class_name PlayerMovement

@export var move_speed: float = 150.0

@onready var sprite: AnimatedSprite2D = $AnimatedSprite2D

var last_direction: String = "down"
var can_move: bool = true  # new flag to enable/disable movement

func _physics_process(delta: float) -> void:
	if not can_move:
		velocity = Vector2.ZERO
		_update_animation(Vector2.ZERO)
		return

	var input_vector := Vector2.ZERO
	
	input_vector.x = Input.get_action_strength("ui_right") - Input.get_action_strength("ui_left")
	input_vector.y = Input.get_action_strength("ui_down") - Input.get_action_strength("ui_up")
	
	if input_vector.length() > 0:
		input_vector = input_vector.normalized()
	
	velocity = input_vector * move_speed
	move_and_slide()

	_update_animation(input_vector)


func _update_animation(direction: Vector2) -> void:
	if not sprite:
		return

	if direction == Vector2.ZERO:
		match last_direction:
			"up":
				sprite.play("idle_up")
			"down":
				sprite.play("idle_down")
			"side":
				sprite.play("idle_side")
	else:
		if abs(direction.x) > abs(direction.y):
			sprite.play("walk_side")
			sprite.flip_h = direction.x < 0
			last_direction = "side"
		elif direction.y < 0:
			sprite.play("walk_up")
			last_direction = "up"
		else:
			sprite.play("walk_down")
			last_direction = "down"
