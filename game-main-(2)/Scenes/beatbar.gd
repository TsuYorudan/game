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

var current_beat: int = 0
var beat_positions: Array = []
var hits: Dictionary = {}

# Smooth movement
var elapsed: float = 0.0
var beat_interval: float = 1.0   # updated by rhythm system
var marker_alpha: float = 0.0    # fade in/out control
var marker_active: bool = false  # true only during phases

func _ready():
	# Precompute beat line X positions
	beat_positions.clear()
	for i in range(total_beats):
		var x = (i / float(total_beats - 1)) * bar_width
		beat_positions.append(x)

	# Connect to rhythm system
	var rhythm = get_tree().get_first_node_in_group("rhythm")
	if rhythm:
		rhythm.connect("beat", Callable(self, "_on_beat"))
		beat_interval = rhythm.beat_time

	queue_redraw()

func _process(delta: float):
	if marker_active:
		elapsed += delta
		if elapsed > beat_interval:
			elapsed = beat_interval # clamp so it doesn’t overshoot
		# fade in quickly
		marker_alpha = lerp(marker_alpha, 1.0, delta * 8.0)
	else:
		# fade out smoothly
		marker_alpha = lerp(marker_alpha, 0.0, delta * 4.0)

	queue_redraw()

func _on_beat(beat_count: int, _timestamp: int):
	if not marker_active:
		return

	current_beat = beat_count % total_beats
	elapsed = 0.0
	queue_redraw()

# === API for TurnManager ===
func start_phase():
	# reset completely for new phase (so it starts from leftmost position)
	marker_active = true
	marker_alpha = 0.0
	current_beat = 0
	elapsed = 0.0
	hits.clear()
	queue_redraw()

func end_phase():
	marker_active = false
	# marker will fade out automatically

func register_input(success: bool):
	if success:
		hits[current_beat] = "hit"
	else:
		hits[current_beat] = "miss"
	queue_redraw()

func reset_bar():
	hits.clear()
	current_beat = 0
	elapsed = 0.0
	marker_alpha = 0.0
	marker_active = false
	queue_redraw()

func _draw():
	# Draw baseline
	draw_line(Vector2(0, bar_height/2), Vector2(bar_width, bar_height/2), line_color, line_thickness)

	# Draw beat dividers
	for pos in beat_positions:
		draw_line(Vector2(pos, 0), Vector2(pos, bar_height), line_color, line_thickness)

	# Only draw marker if visible
	if marker_alpha > 0.01:
		var next_beat = (current_beat + 1) % total_beats
		var start_x = beat_positions[current_beat]
		var end_x = beat_positions[next_beat]
		var t = clamp(elapsed / beat_interval, 0.0, 1.0)
		var marker_x = lerp(start_x, end_x, t)

		var color = marker_color
		color.a = marker_alpha
		draw_line(Vector2(marker_x, 0), Vector2(marker_x, bar_height), color, line_thickness + 1)

	# Draw hit/miss history
	for beat in hits.keys():
		var pos_x = beat_positions[beat]
		var pos_y = bar_height/2 + 20
		var text = "●"
		var color = hit_color if hits[beat] == "hit" else miss_color
		draw_string(get_theme_default_font(), Vector2(pos_x - 8, pos_y), text, HORIZONTAL_ALIGNMENT_LEFT, -1, color)
