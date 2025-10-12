extends Node

@export var bpm: int = 120
@export var input_tolerance: float = 0.2
var beat_time: float
var beat_count: int = 0
var last_beat_time: int = 0
var battle_active: bool = true  # new flag

signal beat(beat_count: int, timestamp: int)

func _ready():
	# Register in "rhythm" group so CommandManager can find it
	if not is_in_group("rhythm"):
		add_to_group("rhythm")

	beat_time = 60.0 / bpm
	$Timer.wait_time = beat_time
	$Timer.start()

	$BeatEffects/TopFlash.modulate.a = 0.0
	$BeatEffects/BottomFlash.modulate.a = 0.0

func flash_screen(color: Color) -> void:
	if not battle_active:
		return  # skip if battle is inactive

	var top = $BeatEffects/TopFlash
	var bot = $BeatEffects/BottomFlash

	top.modulate = color
	bot.modulate = color
	top.modulate.a = 1.0
	bot.modulate.a = 1.0

	var top_tween = get_tree().create_tween()
	var bot_tween = get_tree().create_tween()

	top_tween.tween_property(top, "modulate:a", 0.0, 0.3).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	bot_tween.tween_property(bot, "modulate:a", 0.0, 0.3).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)

func _on_timer_timeout() -> void:
	if not battle_active:
		return  # skip beats if battle ended

	beat_count += 1
	last_beat_time = Time.get_ticks_msec()

	emit_signal("beat", beat_count, last_beat_time)

	$MetronomeSound.play()
	flash_screen(Color.WHITE)

# Call this from TurnManager when battle ends
func stop_rhythm():
	battle_active = false
	$Timer.stop()
