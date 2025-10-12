extends CanvasLayer
class_name ZoomTransition

signal transition_finished

@onready var screen: Control = $Screen
@onready var fade: ColorRect = $Screen/ColorRect
@onready var anim: AnimationPlayer = $AnimationPlayer

func _ready():
	# Ensure fade starts hidden
	fade.visible = false
	fade.modulate.a = 0.0

# Plays transition and waits until finished
func play_transition() -> void:
	fade.visible = true
	fade.modulate.a = 0.0
	screen.scale = Vector2.ONE

	anim.play("zoom_smear")
	await anim.animation_finished

	# Hide fade after transition
	fade.visible = false
	emit_signal("transition_finished")
