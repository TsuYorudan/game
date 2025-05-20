extends ParallaxLayer

@export var star_speed: float = -15
@export var max_offset: Vector2 = Vector2(30, 20)
@export var smoothing: float = 5.0

var base_motion: float = 0.0
var current_mouse_offset: Vector2 = Vector2.ZERO

func _process(delta: float) -> void:
	# Continuous horizontal scroll
	base_motion += star_speed * delta
	
	# Get normalized mouse position
	var viewport_size = get_viewport_rect().size
	var mouse_pos = get_viewport().get_mouse_position()
	var mouse_normalized = (mouse_pos / viewport_size - Vector2(0.5, 0.5)) * 2.0
	var target_mouse_offset = -mouse_normalized * max_offset
	
	# Smooth transition for mouse offset
	current_mouse_offset = current_mouse_offset.lerp(target_mouse_offset, delta * smoothing)
	
	# Combine scroll and mouse offset
	motion_offset = Vector2(base_motion, 0) + current_mouse_offset
