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
var beat_interval: float = 1.0   # will be set by rhythm system

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
		beat_interval = rhythm.beat_time   # directly use rhythm’s beat length

	queue_redraw()


func _process(delta: float):
	elapsed += delta
	if elapsed > beat_interval:
		elapsed = beat_interval # clamp so it doesn’t overshoot
	queue_redraw()


func _on_beat(beat_count: int, _timestamp: int):
	current_beat = beat_count % total_beats
	elapsed = 0.0
	queue_redraw()


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
	queue_redraw()


func _draw():
	# Draw baseline
	draw_line(Vector2(0, bar_height/2), Vector2(bar_width, bar_height/2), line_color, line_thickness)

	# Draw beat dividers
	for pos in beat_positions:
		draw_line(Vector2(pos, 0), Vector2(pos, bar_height), line_color, line_thickness)

	# Marker position interpolates between beats
	var next_beat = (current_beat + 1) % total_beats
	var start_x = beat_positions[current_beat]
	var end_x = beat_positions[next_beat]

	var t = clamp(elapsed / beat_interval, 0.0, 1.0)
	var marker_x = lerp(start_x, end_x, t)

	# Draw marker
	draw_line(Vector2(marker_x, 0), Vector2(marker_x, bar_height), marker_color, line_thickness + 1)

	# Draw hit/miss history
	for beat in hits.keys():
		var pos_x = beat_positions[beat]
		var pos_y = bar_height/2 + 20
		var text = "●"
		var color = hit_color if hits[beat] == "hit" else miss_color
		draw_string(get_theme_default_font(), Vector2(pos_x - 8, pos_y), text, HORIZONTAL_ALIGNMENT_LEFT, -1, color)
