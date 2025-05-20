extends ParallaxLayer

var star_speed = -50

func _process(delta: float) -> void:
	motion_offset.x += star_speed * delta
