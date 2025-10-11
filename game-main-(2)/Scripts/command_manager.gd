extends Node

@onready var player: Node = get_tree().get_first_node_in_group("player")


@export var commands: Dictionary = {
	"pata pata pon pon": "attack",
	"pon pon pata don": "march",
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

# Input visual tracker
@export var input_display: Node  # Assign your InputProgress node

var command_queue: Array = []
var offbeat_flags: Array = []  # parallel array of booleans for each queued input
var max_command_length: int = 4

# Rhythm sync (from RhythmSystem)
@onready var rhythm_system: Node = get_tree().get_first_node_in_group("rhythm")
var last_beat_time: int = 0
var beat_interval: float = 0.0
var input_tolerance: float = 0.2  # seconds (pulled from RhythmSystem if available)

# Track last played success music
var last_success_stream: AudioStream = null


func _ready() -> void:
	randomize()
	$QueueResetTimer.stop()

	$BeatEffects/LeftFlash.modulate.a = 0.0
	$BeatEffects/RightFlash.modulate.a = 0.0

	if input_display and input_display.has_method("reset_input"):
		input_display.call("reset_input")

	if rhythm_system:
		rhythm_system.connect("beat", Callable(self, "_on_beat"))
		beat_interval = 60.0 / rhythm_system.bpm
		input_tolerance = rhythm_system.input_tolerance


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


# Sync to RhythmSystem beats
func _on_beat(beat_count: int, timestamp: int) -> void:
	last_beat_time = timestamp
	beat_interval = 60.0 / rhythm_system.bpm


func is_on_beat(current_time: int) -> bool:
	var delta = abs(current_time - last_beat_time)
	return delta <= int(input_tolerance * 1000)


func handle_input(beat_sound: String, current_time: int) -> void:
	var sound_player: AudioStreamPlayer = null
	match beat_sound:
		"pata": sound_player = pata_sound
		"pon": sound_player = pon_sound
		"don": sound_player = don_sound
		"chaka": sound_player = chaka_sound

	if not sound_player:
		return

	var onbeat: bool = is_on_beat(current_time)

	if not onbeat:
		# Off-beat feedback, but DO NOT clear the queue.
		flash_screen(Color.RED)
		print("❌ Off-beat input detected! Marking as off-beat (won't clear queue).")

		# Play short feedback sound
		sound_player.pitch_scale = randf_range(1.0, 1.05)
		sound_player.play()
		await get_tree().create_timer(0.10).timeout
		sound_player.stop()
	else:
		# On-beat normal flow
		sound_player.pitch_scale = randf_range(0.95, 1.05)
		sound_player.play()
		flash_screen(Color.WHITE)

	# Trigger beatbar mark through register_beat (keeps single point of truth)
	# Trigger "input" animation on the Player node
	if player and player.has_node("AnimatedSprite2D2"):
		var anim_sprite = player.get_node("AnimatedSprite2D2")
		if "input" in anim_sprite.sprite_frames.get_animation_names():
			anim_sprite.play("input")
			var input_anim_length = anim_sprite.sprite_frames.get_frame_count("input") / anim_sprite.sprite_frames.get_animation_speed("input")
			get_tree().create_timer(input_anim_length).timeout.connect(func():
				if "idle" in anim_sprite.sprite_frames.get_animation_names():
					anim_sprite.play("idle")
			)

	# register the beat (this appends to the queue and starts/reset the queue timer)
	register_beat(beat_sound, not onbeat)



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


# register_beat now accepts whether the input was off-beat
func register_beat(beat_sound: String, is_offbeat: bool = false) -> void:
	command_queue.append(beat_sound)
	offbeat_flags.append(is_offbeat)

	if command_queue.size() > max_command_length:
		command_queue.pop_front()
		offbeat_flags.pop_front()

	print("✅ Registered beat. Current Queue:", command_queue, "Offbeat flags:", offbeat_flags)
	$QueueResetTimer.start()

	if input_display and input_display.has_method("add_input"):
		input_display.call("add_input")

	# Also register mark on beatbar (true = player, false = enemy)
	var beatbar = get_tree().get_first_node_in_group("beatbar")
	if beatbar:
		beatbar.call("register_action_mark", false, beat_sound)

	check_command()


func check_command() -> void:
	var command_string = " ".join(command_queue)
	print("Checking command:", command_string)

	if command_queue.size() == max_command_length:
		var turn_manager = get_tree().get_first_node_in_group("turn_manager")

		# If the player is answering in ENEMY_RESOLUTION (counter), send raw response
		if turn_manager and turn_manager.phase == turn_manager.TurnPhase.ENEMY_RESOLUTION:
			turn_manager.record_player_response(command_queue)
			print("📨 Sent player response:", command_queue)
		elif command_string in commands:
			var command_action = commands[command_string]
			# Calculate off-beat penalties
			var offbeat_count: int = 0
			for f in offbeat_flags:
				if f:
					offbeat_count += 1

			var effectiveness: float = clamp(1.0 - 0.25 * offbeat_count, 0.0, 1.0)
			print("✅ Command recognized:", command_action, " | Offbeats:", offbeat_count, " | Effectiveness:", effectiveness)

# Provide effectiveness to player so th eir action uses it

			if player:
				# player script must declare `var current_command_effectiveness: float = 1.0`
				# this will be consumed by Player.attack() / Player.heal()
				if player.has_method("set"):
					# safe dynamic assignment
					player.set("current_command_effectiveness", effectiveness)
				else:
					# fallback
					player.current_command_effectiveness = effectiveness

			execute_command(command_action)
		else:
			print("❌ No command matched.")

		# clear queue and offbeat tracking (same behaviour as before)
		command_queue.clear()
		offbeat_flags.clear()
		if input_display and input_display.has_method("reset_input"):
			input_display.call("reset_input")


func execute_command(action: String) -> void:
	# wait one beat worth of time before executing (preserve previous timing)
	await get_tree().create_timer(beat_interval).timeout
	var battle_node = get_tree().get_first_node_in_group("battle")
	if battle_node:
		battle_node.call("process_command", action)
	else:
		print("⚠️ No battle node found.")

	var turn_manager = get_tree().get_first_node_in_group("turn_manager")
	if turn_manager:
		print("🔄 Player command executed, advancing turn...")
		turn_manager.call("next_phase")

	if success_music:
		success_music.stop()
		if neutral_success_music.size() > 0:
			var valid_choices := neutral_success_music.filter(func(stream): return stream != last_success_stream)
			if valid_choices.is_empty():
				valid_choices = neutral_success_music
			var chosen_stream = valid_choices[randi() % valid_choices.size()]
			last_success_stream = chosen_stream
			success_music.stream = chosen_stream
			success_music.play()


func _on_queue_reset_timer_timeout() -> void:
	if command_queue.size() != 0:
		print("⏳ Timeout! Clearing command queue.")
		command_queue.clear()
		offbeat_flags.clear()
		if input_display and input_display.has_method("reset_input"):
			input_display.call("reset_input")
