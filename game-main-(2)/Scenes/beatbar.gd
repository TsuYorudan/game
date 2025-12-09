extends Control
class_name BeatBar

@export var total_beats: int = 4
@export var bar_width: float = 400.0
@export var bar_height: float = 80.0

@export var line_color: Color = Color.GRAY
@export var marker_color: Color = Color.YELLOW
@export var hit_color: Color = Color.GREEN
@export var miss_color: Color = Color.RED
@export var line_thickness: float = 2.0
@export var input_offset: float = -0.05
@export var mark_fade_time: float = 1.0 # seconds before marks fade

@export var shape_size: float = 16.0
@export var outline_thickness: float = 4.0

@export_enum("PlayStation", "Xbox") var symbol_style: String = "PlayStation"

# --- Xbox color overrides (editable in Inspector) ---
@export var xbox_color_a: Color = Color.hex(0x107C10) # A = green
@export var xbox_color_b: Color = Color.hex(0xD83B01) # B = red
@export var xbox_color_x: Color = Color.hex(0x0050EF) # X = blue
@export var xbox_color_y: Color = Color.hex(0xF2D01F) # Y = yellow



var current_beat: int = 0
var beat_positions: Array = []
var hits: Dictionary = {}
var input_marks: Array = [] # [{x, is_enemy, timestamp, input_type}]

var is_enemy_turn: bool = false
var elapsed: float = 0.0
var beat_interval: float = 1.0
var marker_alpha: float = 0.0
var marker_active: bool = false

func _ready():
	set_custom_minimum_size(Vector2(bar_width, bar_height))

	# Divider positions
	beat_positions.clear()
	for i in range(total_beats):
		var x = (i / float(total_beats - 1)) * bar_width
		beat_positions.append(x)

	# Connect rhythm
	var rhythm = get_tree().get_first_node_in_group("rhythm")
	if rhythm:
		rhythm.connect("beat", Callable(self, "_on_beat"))
		beat_interval = rhythm.beat_time

	queue_redraw()

func _process(delta: float):
	if marker_active:
		elapsed += delta
		elapsed = min(elapsed, beat_interval)
		marker_alpha = lerp(marker_alpha, 1.0, delta * 8.0)
	else:
		marker_alpha = lerp(marker_alpha, 0.0, delta * 4.0)

	# Fade input marks
	for i in range(input_marks.size() - 1, -1, -1):
		var age = (Time.get_ticks_msec() / 1000.0) - input_marks[i].timestamp
		if age >= mark_fade_time:
			input_marks.remove_at(i)

	queue_redraw()

func _on_beat(beat_count: int, _timestamp: int):
	if not marker_active:
		return
	current_beat = beat_count % total_beats
	elapsed = 0.0
	queue_redraw()

# === API ===
func start_phase():
	marker_active = true
	marker_alpha = 0.0
	current_beat = 0
	elapsed = 0.0
	hits.clear()
	input_marks.clear()
	queue_redraw()

func end_phase():
	marker_active = false

func register_input(success: bool):
	hits[current_beat] = "hit" if success else "miss"
	queue_redraw()

func register_action_mark(is_enemy: bool, input_type: String = ""):
	if not marker_active:
		return

	var next_beat = (current_beat + 1) % total_beats
	var start_x = beat_positions[current_beat]
	var end_x = beat_positions[next_beat]

	var adjusted_elapsed = clamp(elapsed + input_offset, 0.0, beat_interval)
	var t = adjusted_elapsed / beat_interval
	var marker_x = lerp(start_x, end_x, t)
	marker_x = clamp(marker_x, 0, bar_width)

	input_marks.append({
		"x": marker_x,
		"is_enemy": is_enemy,
		"timestamp": Time.get_ticks_msec() / 1000.0,
		"input_type": input_type
	})

	queue_redraw()

func reset_bar():
	hits.clear()
	input_marks.clear()
	current_beat = 0
	elapsed = 0.0
	marker_alpha = 0.0
	marker_active = false
	queue_redraw()

# === DRAWING ===
func _draw():
	# Baseline
	draw_line(Vector2(0, bar_height / 2), Vector2(bar_width, bar_height / 2), line_color, line_thickness)

	# Beat dividers
	for pos in beat_positions:
		draw_line(Vector2(pos, 0), Vector2(pos, bar_height), line_color, line_thickness)

	# Sliding marker
	if marker_alpha > 0.01:
		var next_beat = (current_beat + 1) % total_beats
		var start_x = beat_positions[current_beat]
		var end_x = beat_positions[next_beat]
		var t = clamp(elapsed / beat_interval, 0.0, 1.0)
		var marker_x = lerp(start_x, end_x, t)
		var color = marker_color if not is_enemy_turn else Color.RED
		color.a = marker_alpha
		draw_line(Vector2(marker_x, 0), Vector2(marker_x, bar_height), color, line_thickness + 1)

	# Draw all input marks
	for mark in input_marks:
		draw_input_mark(mark)


func draw_input_mark(mark: Dictionary):
	var is_ps = symbol_style == "PlayStation"
	var base_color = Color.RED if mark.is_enemy else Color.CYAN
	var age = Time.get_ticks_msec() / 1000.0 - mark.timestamp
	var fade = clamp(1.0 - age / mark_fade_time, 0.0, 1.0)
	var alpha_color = Color(base_color.r, base_color.g, base_color.b, fade)

	var x = mark.x
	var y = bar_height / 2
	var s = shape_size

	# ---------------- PLAYSTATION SYMBOLS (unchanged) ----------------
	if is_ps:
		match mark.input_type:
			"pata": # Square
				draw_rect(Rect2(x - s/2, y - s/2, s, s), Color(1, 1, 1, fade))
				draw_rect(Rect2(x - s/2, y - s/2, s, s), alpha_color, false, outline_thickness)

			"pon": # Circle
				draw_circle(Vector2(x, y), s/2, Color(1, 1, 1, fade))
				draw_circle(Vector2(x, y), s/2, alpha_color, false, outline_thickness)

			"don": # Cross
				var o = s / 2
				draw_line(Vector2(x - o, y - o), Vector2(x + o, y + o), alpha_color, outline_thickness)
				draw_line(Vector2(x - o, y + o), Vector2(x + o, y - o), alpha_color, outline_thickness)

			"chaka": # Triangle
				var pts = [
					Vector2(x, y - s/2),
					Vector2(x - s/2, y + s/2),
					Vector2(x + s/2, y + s/2)
				]
				draw_colored_polygon(pts, Color(1, 1, 1, fade))
				draw_polyline(pts + [pts[0]], alpha_color, outline_thickness)

			_:
				draw_circle(Vector2(x, y), 3, alpha_color)
		return

	# ---------------- XBOX SYMBOLS (TEXT ONLY, configurable colors) ----------------
	var font: Font = get_theme_default_font()
	var font_size: int = int(round(s * 2.0))
	var pos := Vector2(x - font_size * 0.35, y + font_size * 0.35)

	match mark.input_type:
		"pata": # X button (uses xbox_color_x)
			var col = xbox_color_x
			col.a = fade
			draw_string(font, pos, "X", HORIZONTAL_ALIGNMENT_LEFT, -1, font_size, col)

		"pon": # B button (uses xbox_color_b)
			var col = xbox_color_b
			col.a = fade
			draw_string(font, pos, "B", HORIZONTAL_ALIGNMENT_LEFT, -1, font_size, col)

		"don": # A button (uses xbox_color_a)
			var col = xbox_color_a
			col.a = fade
			draw_string(font, pos, "A", HORIZONTAL_ALIGNMENT_LEFT, -1, font_size, col)

		"chaka": # Y button (uses xbox_color_y)
			var col = xbox_color_y
			col.a = fade
			draw_string(font, pos, "Y", HORIZONTAL_ALIGNMENT_LEFT, -1, font_size, col)

		_:
			draw_string(font, pos, "?", HORIZONTAL_ALIGNMENT_LEFT, -1, font_size, alpha_color)
