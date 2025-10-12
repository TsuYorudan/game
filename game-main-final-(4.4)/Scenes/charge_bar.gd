extends ProgressBar
class_name ChargeUI

@export var max_charges: int = 6
@export var charge_spacing: float = 4.0
@export var charge_height: float = 16.0
@export var fill_color: Color = Color(1, 1, 1)
@export var empty_color: Color = Color(0.2, 0.2, 0.2)
@export var divider_color: Color = Color(0, 0, 0)
@export var glow_color: Color = Color(1, 1, 0.5)
@export var consume_color: Color = Color(1, 0.5, 0.5)
@export var glow_duration: float = 0.3
@export var pulse_strength: float = 1.3  # scale multiplier
@export var pulse_speed: float = 10.0    # higher is faster

var current_charges: int = 0
var _last_charges: int = 0

# Animation state
var _glow_index: int = -1
var _glow_timer: float = 0.0
var _consume_index: int = -1
var _consume_timer: float = 0.0

func _ready():
	min_value = 0
	max_value = max_charges
	value = current_charges
	queue_redraw()

	var player = get_tree().get_first_node_in_group("player")
	if player:
		player.connect("charges_changed", Callable(self, "_on_charges_changed"))

func _on_charges_changed(charges: int):
	_last_charges = current_charges
	if charges > current_charges:
		_glow_index = current_charges
		_glow_timer = glow_duration
	elif charges < current_charges:
		_consume_index = charges
		_consume_timer = glow_duration

	current_charges = charges
	value = current_charges
	queue_redraw()

func _process(delta: float):
	var redraw_needed = false

	# Glow timer
	if _glow_timer > 0:
		_glow_timer -= delta
		if _glow_timer <= 0:
			_glow_index = -1
		redraw_needed = true

	# Consume timer
	if _consume_timer > 0:
		_consume_timer -= delta
		if _consume_timer <= 0:
			_consume_index = -1
		redraw_needed = true

	if redraw_needed:
		queue_redraw()

func _draw():
	var total_width = size.x
	var slot_width = (total_width - (max_charges - 1) * charge_spacing) / max_charges
	var y = (size.y - charge_height) / 2

	for i in range(max_charges):
		var x = i * (slot_width + charge_spacing)
		var color: Color = fill_color if i < current_charges else empty_color

		# Glow animation
		if i == _glow_index and _glow_timer > 0:
			var t = _glow_timer / glow_duration
			color = fill_color.lerp(glow_color, t)

		# Consume animation
		if i == _consume_index and _consume_timer > 0:
			var t = _consume_timer / glow_duration
			color = fill_color.lerp(consume_color, t)

		# Pulse scale animation
		var pulse = 1.0
		if i == _glow_index and _glow_timer > 0:
			pulse += (pulse_strength - 1.0) * sin((1.0 - _glow_timer / glow_duration) * PI)
		if i == _consume_index and _consume_timer > 0:
			pulse += (pulse_strength - 1.0) * sin((1.0 - _consume_timer / glow_duration) * PI)

		var scaled_width = slot_width * pulse
		var scaled_height = charge_height * pulse
		var offset_x = (slot_width - scaled_width) / 2
		var offset_y = (charge_height - scaled_height) / 2

		draw_rect(Rect2(x + offset_x, y + offset_y, scaled_width, scaled_height), color)

		# Divider lines
		if i < max_charges - 1:
			draw_line(
				Vector2(x + slot_width + charge_spacing / 2, y),
				Vector2(x + slot_width + charge_spacing / 2, y + charge_height),
				divider_color,
				2
			)
