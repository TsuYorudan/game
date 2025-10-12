extends CanvasLayer

signal on_fade_in_finished
signal on_fade_out_finished
signal on_transition_finished

@onready var color_rect: ColorRect = $ColorRect
@onready var animation_player: AnimationPlayer = $AnimationPlayer

func _ready():
	color_rect.visible = false
	# connect using Callable to be explicit and avoid issues
	animation_player.animation_finished.connect(Callable(self, "_on_animation_finished"))

func _on_animation_finished(anim_name: String) -> void:
	if anim_name == "fade_black":
		emit_signal("on_fade_out_finished")
	elif anim_name == "fade_normal":
		color_rect.visible = false
		emit_signal("on_fade_in_finished")

# --- original API (unchanged) ---
func fade_out() -> void:
	color_rect.visible = true
	animation_player.play("fade_black")  # Fade to black

func fade_in() -> void:
	color_rect.visible = true
	animation_player.play("fade_normal") # Fade back to normal (transparent)

# transition() already awaited signals in your earlier version,
# keep a clear async flow here too:
func transition() -> void:
	await fade_out_and_wait()
	await fade_in_and_wait()
	emit_signal("on_transition_finished")

# --- new convenience async helpers (added) ---
# Awaitable: call to fade out and wait for the animation to finish
func fade_out_and_wait() -> void:
	fade_out()
	await on_fade_out_finished

# Awaitable: call to fade in and wait for the animation to finish
func fade_in_and_wait() -> void:
	fade_in()
	await on_fade_in_finished

# Alias that does "fade out (to black) then fade in" — matches the name you tried to call
func fade_in_from_black() -> void:
	# fade to black first, wait, then fade back in
	await fade_out_and_wait()
	await fade_in_and_wait()
