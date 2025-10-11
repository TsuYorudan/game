extends Control
class_name TimelineBar

@export var phases: Array = [
	"Player",
	"Player Resolution",
	"Enemy",
	"Counter",
	"Enemy Resolution"
]

@export var bar_width: float = 600.0
@export var bar_height: float = 24.0
@export var bg_color: Color = Color(0, 0, 0, 0.25)
@export var divider_color: Color = Color(1, 1, 1, 0.35)
@export var active_color: Color = Color(1.0, 0.85, 0.2, 1.0)
@export var line_thickness: float = 2.0
@export var marker_color: Color = Color(1, 1, 0)
@export var marker_width: float = 3.0

# Rhythm / marker
var rhythm_system: Node
var beat_interval: float = 1.0
var beats_per_phase: int = 4
var elapsed: float = 0.0
var beat_in_phase: int = 0
var marker_active: bool = false
var player_has_action: bool = false

# Phase tracking
var current_phase: int = 0

func _ready():
	set_custom_minimum_size(Vector2(bar_width, bar_height))
	queue_redraw()

	# Connect to rhythm system
	rhythm_system = get_tree().get_first_node_in_group("rhythm")
	if rhythm_system:
		rhythm_system.connect("beat", Callable(self, "_on_beat"))
		beat_interval = rhythm_system.beat_time

func _process(delta: float) -> void:
	if not marker_active:
		return

	elapsed += delta
	elapsed = clamp(elapsed, 0.0, beat_interval)
	queue_redraw()

func _on_beat(_beat_count: int, _timestamp: int) -> void:
	if not marker_active:
		return

	# Advance the beat in current phase
	beat_in_phase += 1

	# Loop marker in player phase if action not done
	if current_phase == 0 and not player_has_action:
		beat_in_phase = beat_in_phase % beats_per_phase
	else:
		beat_in_phase = beat_in_phase % beats_per_phase

	elapsed = 0.0
	queue_redraw()

# =========================
# Phase control
# =========================
func set_phase(index: int) -> void:
	current_phase = clamp(index, 0, max(0, phases.size() - 1))
	player_has_action = false
	marker_active = true
	beat_in_phase = 0
	elapsed = 0.0
	queue_redraw()

func end_phase():
	marker_active = false
	queue_redraw()

func set_player_action_done():
	player_has_action = true

# =========================
# Drawing
# =========================
func _draw() -> void:
	# Background
	draw_rect(Rect2(Vector2.ZERO, Vector2(bar_width, bar_height)), bg_color)

	var count: int = phases.size()
	if count < 2:
		return

	# Draw phase dividers
	for i in range(count):
		var x: float = (i / float(count - 1)) * bar_width
		var col: Color = active_color if i == current_phase else divider_color
		draw_line(Vector2(x, 0), Vector2(x, bar_height), col, line_thickness)

	# Draw sliding marker
	if marker_active:
		var section_start: float = (current_phase / float(count - 1)) * bar_width
		var section_end: float = ((current_phase + 1) / float(count - 1)) * bar_width
		var t: float = (float(beat_in_phase) + elapsed / beat_interval) / float(beats_per_phase)
		t = clamp(t, 0.0, 1.0)
		var marker_x: float = lerp(section_start, section_end, t)
		draw_line(Vector2(marker_x, 0), Vector2(marker_x, bar_height), marker_color, marker_width)
