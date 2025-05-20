extends CanvasLayer

signal on_fade_in_finished
signal on_fade_out_finished


@onready var color_rect: ColorRect = $ColorRect
@onready var animation_player: AnimationPlayer = $AnimationPlayer

func _ready():
	color_rect.visible = false
	animation_player.animation_finished.connect(_on_animation_finished)

func _on_animation_finished(anim_name: String) -> void:
	if anim_name == "fade_black":
		emit_signal("on_fade_out_finished")
	elif anim_name == "fade_normal":
		color_rect.visible = false
		emit_signal("on_fade_in_finished")

func fade_out() -> void:
	color_rect.visible = true
	animation_player.play("fade_black")  # Fade to black

func fade_in() -> void:
	color_rect.visible = true
	animation_player.play("fade_normal") # Fade back to normal (transparent)
