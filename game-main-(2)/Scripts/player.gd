extends CharacterBody2D

@export var speed: float = 500.0  # Movement speed
@export var jump_velocity: float = -500.0  # Jump velocity (if needed for future use)
var gravity = ProjectSettings.get_setting("physics/2d/default_gravity")  # Gravity

# Variable to track whether the character is marching or retreating
var is_marching: bool = false
var is_retreating: bool = false

# Method to start marching
func start_marching():
	print("Character starting to march.")
	is_marching = true  # Set the marching flag to true
	is_retreating = false  # Ensure retreating is stopped
	$MarchTimer.start()  # Start the march timer

# Method to start retreating (opposite of marching)
func start_retreat():
	print("Character starting to retreat.")
	is_retreating = true  # Set the retreat flag to true
	is_marching = false  # Ensure marching is stopped
	$MarchTimer.start()  # You can use the same timer logic if you need a time duration for retreat

# Method to stop the movement (optional)
func stop_moving():
	print("Character stopping movement.")  # Debugging line to check if it's being called
	is_marching = false
	is_retreating = false
	velocity.x = 0

# _physics_process handles character movement and physics
func _physics_process(delta: float) -> void:
	if not is_on_floor():
		velocity.y += gravity * delta  # Apply gravity if the character is in the air
	
	var direction = Vector2.ZERO  # No input for direction by default

	# If the character is marching, move it to the right
	if is_marching:
		velocity.x = speed  # Move horizontally to the right
	# If the character is retreating, move it to the left
	elif is_retreating:
		velocity.x = -speed  # Move horizontally to the left (retreating)

	# Apply movement and handle collisions
	move_and_slide()

# Called when the timer times out
func _on_march_timer_timeout() -> void:
	print("March timer timed out.")  # Debugging line to see if the timeout is triggered
	stop_moving()  # This will stop the movement
