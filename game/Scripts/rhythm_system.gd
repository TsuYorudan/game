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
	print("RhythmSystem started. Beat time:", beat_time)  # Debugging

func _on_timer_timeout() -> void:
	beat_count += 1  # Increment beat count
	print("BEAT:", beat_count)  # Debugging
	emit_signal("beat")
	$MetronomeSound.play()
