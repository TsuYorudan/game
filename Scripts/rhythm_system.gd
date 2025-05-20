extends Node

@export var bpm: int = 120
@export var input_tolerance: float = 0.2
var beat_time: float
var beat_count: int = 0

signal beat

func _ready():
	beat_time = 60.0 / bpm
	$Timer.wait_time = beat_time
	$Timer.start()
	$BeatEffects/TopFlash.modulate.a = 0.0
	$BeatEffects/BottomFlash.modulate.a = 0.0
	#print("RhythmSystem started. Beat time:", beat_time)  # Debugging

func flash_screen(color: Color) -> void:
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


	#print("✅ Tween animations applied.")

func _on_timer_timeout() -> void:
	beat_count += 1  # Increment beat count
	#print("BEAT:", beat_count)  # Debugging
	emit_signal("beat")
	$MetronomeSound.play()
	flash_screen(Color.WHITE)
