extends Sprite2D

func _ready() -> void:
	$Area2D/AnimatedSprite2D.play()

func _on_area_2d_body_entered(body: Node2D) -> void:
	if body.is_in_group("player"):
		body.on_cp_reached()
