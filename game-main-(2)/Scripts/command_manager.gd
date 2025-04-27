extends Node

@export var commands: Dictionary = {
	"pata pata pata pon": "march",
	"pon pon pata pon": "counter_attack",
	"chaka chaka pata pon": "shield",
	"don don chaka chaka": "calm_enemy",
	"pon pata pon pata": "retreat"
}

var command_queue: Array = []
var max_command_length: int = 4

# Beat timing setup
const BPM: int = 120
var beat_interval: float = 60.0 / BPM
var last_beat_time: int
const BEAT_WINDOW: int = 250  # Wider window (±125ms)

func _ready():
	last_beat_time = Time.get_ticks_msec()
	$QueueResetTimer.stop()

func _process(delta):
	var current_time = Time.get_ticks_msec()

	if Input.is_action_just_pressed("pata"):
		register_beat("pata", current_time)
	if Input.is_action_just_pressed("pon"):
		register_beat("pon", current_time)
	if Input.is_action_just_pressed("don"):
		register_beat("don", current_time)
	if Input.is_action_just_pressed("chaka"):
		register_beat("chaka", current_time)

	# Update beat tracking
	if current_time - last_beat_time >= beat_interval * 1000:
		last_beat_time += int(beat_interval * 1000)

func is_on_beat(current_time: int) -> bool:
	var time_since_last_beat = (current_time - last_beat_time) % int(beat_interval * 1000)
	return time_since_last_beat <= BEAT_WINDOW / 2 or time_since_last_beat >= int(beat_interval * 1000) - BEAT_WINDOW / 2

func register_beat(beat_sound: String, current_time: int) -> void:
	# Check if on beat
	if not is_on_beat(current_time):
		print("❌ Off-beat input detected! Resetting command queue.")
		command_queue.clear()
		$QueueResetTimer.stop()
		return

	# Otherwise, register normally
	command_queue.append(beat_sound)
	if command_queue.size() > max_command_length:
		command_queue.pop_front()

	print("✅ Registered beat. Current Queue:", command_queue)

	$QueueResetTimer.start()
	check_command()

func check_command() -> void:
	var command_string = " ".join(command_queue)
	print("Checking command:", command_string)

	if command_queue.size() == max_command_length:
		if command_string in commands:
			print("✅ Command recognized:", commands[command_string])
			execute_command(commands[command_string])
		else:
			print("❌ No command matched.")
		command_queue.clear()

func execute_command(action: String) -> void:
	await get_tree().create_timer(beat_interval).timeout  # Wait for next beat
	var battle_node = get_tree().get_first_node_in_group("battle")
	if battle_node:
		battle_node.process_command(action)
	else:
		print("⚠️ No battle node found to process the action.")

func _on_queue_reset_timer_timeout() -> void:
	if command_queue.size() != 0:
		print("⏳ Timeout! Clearing command queue.")
		command_queue.clear()
