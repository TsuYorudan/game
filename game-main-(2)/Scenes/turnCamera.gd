extends Camera2D
class_name TurnCamera

@export var zoom_speed: float = 5.0
@export var cinematic_speed: float = 2.0  # Slower speed for cinematic transitions

# Zoom presets
@export var normal_zoom: Vector2 = Vector2(1.2, 1.2)
@export var focused_zoom: Vector2 = Vector2(1.1, 1.1)

# Position presets
@export var player_offset: Vector2 = Vector2(-100, 0)
@export var enemy_offset: Vector2 = Vector2(100, 0)
@export var center_offset: Vector2 = Vector2(0, 0)

# Camera shake parameters
@export var shake_amplitude: float = 15.0
@export var shake_duration: float = 0.3

var target_offset: Vector2
var target_zoom: Vector2
var _default_speed: float

# Shake variables
var _shake_timer: float = 0.0
var _original_offset: Vector2

func _ready():
	target_zoom = normal_zoom
	target_offset = center_offset
	_original_offset = center_offset
	_default_speed = zoom_speed

	var turn_manager = get_tree().get_first_node_in_group("turn_manager")
	if turn_manager:
		turn_manager.connect("phase_changed", Callable(self, "_on_phase_changed"))

	# Connect to player damage
	var player = get_tree().get_first_node_in_group("player")
	if player:
		player.connect("took_damage", Callable(self, "_on_player_hit"))

func _process(delta: float) -> void:
	# Smooth zoom and offset
	offset = offset.lerp(target_offset, delta * zoom_speed)
	zoom = zoom.lerp(target_zoom, delta * zoom_speed)

	# Apply shake if active
	if _shake_timer > 0:
		_shake_timer -= delta
		offset += Vector2(randf_range(-1,1), randf_range(-1,1)) * shake_amplitude * (_shake_timer / shake_duration)

func _on_phase_changed(phase: String) -> void:
	match phase:
		"PLAYER_INPUT":
			target_offset = player_offset
			target_zoom = focused_zoom
			zoom_speed = _default_speed

		"PLAYER_RESOLUTION":
			target_offset = center_offset
			target_zoom = normal_zoom
			zoom_speed = _default_speed

		"ENEMY_INPUT":
			target_offset = enemy_offset
			target_zoom = focused_zoom
			zoom_speed = _default_speed

		"ENEMY_RESOLUTION":
			target_offset = center_offset
			target_zoom = normal_zoom
			zoom_speed = _default_speed

		"BATTLE_END":
			target_offset = center_offset
			target_zoom = normal_zoom
			zoom_speed = cinematic_speed

func _on_player_hit():
	_shake_timer = shake_duration
