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

var target_offset: Vector2
var target_zoom: Vector2
var _default_speed: float

func _ready():
	target_zoom = normal_zoom
	target_offset = center_offset
	_default_speed = zoom_speed

	var turn_manager = get_tree().get_first_node_in_group("turn_manager")
	if turn_manager:
		turn_manager.connect("phase_changed", Callable(self, "_on_phase_changed"))

func _process(delta: float) -> void:
	offset = offset.lerp(target_offset, delta * zoom_speed)
	zoom = zoom.lerp(target_zoom, delta * zoom_speed)

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
			# Shift camera to neutral with cinematic easing
			target_offset = center_offset
			target_zoom = normal_zoom
			zoom_speed = cinematic_speed
