extends Node

#test

@export var commands: Dictionary = {
	"pata pata pon pon": "march",
	"pon pon pata don": "attack",
	"chaka chaka pata pon": "heal",
	"don don chaka chaka": "calm_enemy",
	"pon pata pon pata": "retreat"
}

# Audio players (assign in Inspector)
@export var success_music: AudioStreamPlayer
@export var pata_sound: AudioStreamPlayer
@export var pon_sound: AudioStreamPlayer
@export var don_sound: AudioStreamPlayer
@export var chaka_sound: AudioStreamPlayer

# Success music variations
@export var neutral_success_music: Array[AudioStream] = []
@export var combo_success_music: Array[AudioStream] = []
@export var resonance_success_music: Array[AudioStream] = []

# Input visual tracker (InputProgress)
@export var input_display: Node  # Assign your InputProgress node in the editor

var command_queue: Array = []
var max_command_length: int = 4

# Beat timing setup
const BPM: int = 120
var beat_interval: float = 60.0 / BPM
var last_beat_time: int
const BEAT_WINDOW: int = 275  # ±137ms around beat

# Combo system
var combo_count: int = 0
var combo_string: String = ""
var combo_timeout_timer: Timer
var combo_reset_time: float = 5.0

# Combo protection window (4 beats after valid input)
var combo_protection_timer: Timer
var combo_protection_active: bool = false

# Track last played success music to avoid repetition
var last_success_stream: AudioStream = null

@onready var combo_label: Label = $"../UI/ComboLabelPersistent"
var combo_tween: Tween = null

func _ready() -> void:
	randomize()
	last_beat_time = Time.get_ticks_msec()
	$QueueResetTimer.stop()

	$BeatEffects/LeftFlash.modulate.a = 0.0
	$BeatEffects/RightFlash.modulate.a = 0.0

	combo_timeout_timer = Timer.new()
	combo_timeout_timer.wait_time = combo_reset_time
	combo_timeout_timer.one_shot = true
	combo_timeout_timer.connect("timeout", Callable(self, "_on_combo_timeout"))
	add_child(combo_timeout_timer)

	combo_protection_timer = Timer.new()
	combo_protection_timer.wait_time = beat_interval * 4.0
	combo_protection_timer.one_shot = true
	combo_protection_timer.connect("timeout", Callable(self, "_on_combo_protection_timeout"))
	add_child(combo_protection_timer)

	if combo_label:
		combo_label.text = ""
		combo_label.visible = false
		combo_label.modulate.a = 0.0
		combo_label.scale = Vector2.ONE

	if input_display and input_display.has_method("reset_input"):
		input_display.call("reset_input")

func _process(_delta: float) -> void:
	var current_time = Time.get_ticks_msec()

	if Input.is_action_just_pressed("pata"):
		handle_input("pata", current_time)
	if Input.is_action_just_pressed("pon"):
		handle_input("pon", current_time)
	if Input.is_action_just_pressed("don"):
		handle_input("don", current_time)
	if Input.is_action_just_pressed("chaka"):
		handle_input("chaka", current_time)

	if current_time - last_beat_time >= beat_interval * 1000:
		last_beat_time += int(beat_interval * 1000)

func is_on_beat(current_time: int) -> bool:
	var time_since_last_beat = (current_time - last_beat_time) % int(beat_interval * 1000)
	return time_since_last_beat <= BEAT_WINDOW / 2 or time_since_last_beat >= int(beat_interval * 1000) - BEAT_WINDOW / 2

func handle_input(beat_sound: String, current_time: int) -> void:
	if combo_protection_active:
		print("⚠️ Input during combo cooldown! Combo reset.")
		reset_combo()

	var player: AudioStreamPlayer = null

	match beat_sound:
		"pata": player = pata_sound
		"pon": player = pon_sound
		"don": player = don_sound
		"chaka": player = chaka_sound

	if not player:
		return

	if not is_on_beat(current_time):
		flash_screen(Color.RED)
		print("❌ Off-beat input detected! Resetting command queue and combo.")
		command_queue.clear()
		reset_combo()
		$QueueResetTimer.stop()

		if input_display and input_display.has_method("reset_input"):
			input_display.call("reset_input")

		player.pitch_scale = randf_range(1.0, 1.05)
		player.play()
		await get_tree().create_timer(0.1).timeout
		player.stop()
		return

	player.pitch_scale = randf_range(0.95, 1.05)
	player.play()
	flash_screen(Color.WHITE)
	register_beat(beat_sound)

func flash_screen(color: Color) -> void:
	var left = $BeatEffects/LeftFlash
	var right = $BeatEffects/RightFlash

	if not left or not right:
		print("⚠️ Flash nodes missing.")
		return

	left.modulate = color
	right.modulate = color
	left.modulate.a = 1.0
	right.modulate.a = 1.0

	var left_tween = get_tree().create_tween()
	var right_tween = get_tree().create_tween()

	left_tween.tween_property(left, "modulate:a", 0.0, 0.3).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	right_tween.tween_property(right, "modulate:a", 0.0, 0.3).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)

func register_beat(beat_sound: String) -> void:
	command_queue.append(beat_sound)
	if command_queue.size() > max_command_length:
		command_queue.pop_front()

	print("✅ Registered beat. Current Queue:", command_queue)
	$QueueResetTimer.start()

	if input_display and input_display.has_method("add_input"):
		input_display.call("add_input")

	check_command()

func check_command() -> void:
	var command_string = " ".join(command_queue)
	print("Checking command:", command_string)

	if command_queue.size() == max_command_length:
		if command_string in commands:
			var command_action = commands[command_string]
			print("✅ Command recognized:", command_action)
			execute_command(command_action)
			increment_combo()
		else:
			print("❌ No command matched.")
			reset_combo()

		command_queue.clear()
		if input_display and input_display.has_method("reset_input"):
			input_display.call("reset_input")

func execute_command(action: String) -> void:
	await get_tree().create_timer(beat_interval).timeout
	var battle_node = get_tree().get_first_node_in_group("battle")
	if battle_node:
		battle_node.call("process_command", action)
	else:
		print("⚠️ No battle node found.")

	if success_music:
		success_music.stop()

		var music_list: Array[AudioStream] = []
		if combo_count >= 10:
			music_list = resonance_success_music
		elif combo_count >= 6:
			music_list = combo_success_music
		else:
			music_list = neutral_success_music

		var valid_choices := music_list.filter(func(stream): return stream != last_success_stream)
		if valid_choices.is_empty():
			valid_choices = music_list

		if valid_choices.size() > 0:
			var chosen_stream = valid_choices[randi() % valid_choices.size()]
			last_success_stream = chosen_stream
			success_music.stream = chosen_stream
			success_music.play()

func increment_combo() -> void:
	combo_count += 1

	if combo_count >= 10:
		combo_string = "RESONANCE"
	else:
		combo_string = "FLOW x%d!" % combo_count

	print(combo_string)
	show_combo_text(combo_string)
	combo_timeout_timer.start()

	combo_protection_active = true
	combo_protection_timer.start()

	if combo_count % 5 == 0 and combo_count < 10:
		print("✨ Combo bonus triggered!")

func show_combo_text(text: String) -> void:
	if not combo_label:
		return

	combo_label.text = text
	combo_label.visible = true
	combo_label.modulate = Color(1, 1, 1, 1)

	var target_scale = Vector2(1, 1)
	if combo_count > 0:
		var scale_factor = lerp(1.0, 2.0, min(combo_count, 10) / 10.0)
		target_scale = Vector2(scale_factor, scale_factor)

	combo_label.scale = target_scale * 1.3

	if combo_tween and combo_tween.is_running():
		combo_tween.kill()

	combo_tween = get_tree().create_tween()
	combo_tween.tween_property(combo_label, "scale", target_scale, 0.2).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)

func reset_combo() -> void:
	if combo_count > 0:
		print("💥 Combo broken at x%d" % combo_count)
	combo_count = 0
	combo_string = ""
	combo_timeout_timer.stop()
	combo_protection_timer.stop()
	combo_protection_active = false
	hide_combo_text()

func hide_combo_text() -> void:
	if not combo_label:
		return

	var fade_tween = get_tree().create_tween()
	fade_tween.tween_property(combo_label, "modulate:a", 0.0, 0.4).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN)
	fade_tween.tween_callback(Callable(func():
		combo_label.visible = false
	))

func _on_combo_timeout() -> void:
	print("⏱️ Combo expired.")
	reset_combo()

func _on_combo_protection_timeout() -> void:
	combo_protection_active = false

func _on_queue_reset_timer_timeout() -> void:
	if command_queue.size() != 0:
		print("⏳ Timeout! Clearing command queue.")
		command_queue.clear()
		if input_display and input_display.has_method("reset_input"):
			input_display.call("reset_input")
