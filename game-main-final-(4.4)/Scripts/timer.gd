extends Node

signal beat_tick(beat_count)

@export var bpm: int = 120  # Adjust BPM as needed
var beat_time: float
var beat_count: int = 0
var timer: Timer

func _ready():
	beat_time = 60.0 / bpm  # Convert BPM to seconds per beat
	print("Beat time:", beat_time)  # Debug print

	timer = Timer.new()
	timer.wait_time = beat_time
	timer.one_shot = false
	timer.timeout.connect(_on_beat)
	add_child(timer)
	timer.start()
	
	print("Timer started")  # Debug print

func _on_beat():
	beat_count += 1
	print("Beat:", beat_count)  # Debug print
	emit_signal("beat_tick", beat_count)
