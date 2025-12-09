extends Control
class_name CommandCheatSheet

# ---------------- CONTROLLER STYLE ----------------
@export_enum("PlayStation", "Xbox") var controller_style: String = "PlayStation"

# Xbox button colors (customizable in Inspector)
@export var xbox_color_x: Color = Color.hex(0x0050EF) # Blue
@export var xbox_color_b: Color = Color.hex(0xD83B01) # Red
@export var xbox_color_a: Color = Color.hex(0x107C10) # Green
@export var xbox_color_y: Color = Color.hex(0xF2D01F) # Yellow
@export var xbox_font_size_multiplier: float = 1.8

# Commands -> sequences
@export var commands: Dictionary = {
	"charge":  ["pon", "pon", "pata", "don"],
	"Attack": ["pata", "pata", "pon", "pon"],
	"Heal":   ["chaka", "chaka", "pata", "pon"],
	"Retreat": ["pon", "pata", "pon", "pata"]
}

# Layout parameters
@export var shape_size: float = 20.0
@export var outline_thickness: float = 3.0
@export var shape_spacing: float = 8.0
@export var row_spacing: float = 8.0
@export var label_margin_left: float = 12.0
@export var label_font: Font
@export var label_color: Color = Color(1,1,1)

var shape_colors: Dictionary = {
	"pata": Color.WHITE,
	"pon": Color.WHITE,
	"don": Color.WHITE,
	"chaka": Color.WHITE
}

# ---------------- SHAPES PREVIEW CLASS ----------------
class ShapesPreview:
	extends Control

	var sequence: Array = []
	var shape_size: float
	var spacing: float
	var outline_thickness: float
	var shape_colors: Dictionary
	var parent_ref: CommandCheatSheet

	func _ready() -> void:
		_update_min_size()
		queue_redraw()

	func _update_min_size() -> void:
		var width = max(1, sequence.size()) * shape_size + max(0, sequence.size() - 1) * spacing
		set_custom_minimum_size(Vector2(width, shape_size + 8))

	func _draw() -> void:
		var x = shape_size * 0.5
		var y = (shape_size + 8.0) * 0.5
		for input_type in sequence:
			_draw_symbol(Vector2(x, y), input_type)
			x += shape_size + spacing

	# ---------------- SYMBOL DRAWER ----------------
	func _draw_symbol(pos: Vector2, input_type: String) -> void:
		if parent_ref.controller_style == "PlayStation":
			_draw_playstation(pos, input_type)
		else:
			_draw_xbox(pos, input_type)

	# ---------------- PLAYSTATION SYMBOLS ----------------
	func _draw_playstation(pos: Vector2, input_type: String) -> void:
		var s = shape_size
		var x = pos.x
		var y = pos.y
		var white_fill = Color(0.2,0.2,0.2)
		var color = shape_colors.get(input_type, Color(0.8,0.8,0.8))

		match input_type:
			"pata": # Square
				draw_rect(Rect2(x - s/2, y - s/2, s, s), white_fill)
				draw_rect(Rect2(x - s/2, y - s/2, s, s), color, false, outline_thickness)

			"pon": # Circle
				draw_circle(Vector2(x, y), s/2, white_fill)
				draw_circle(Vector2(x, y), s/2, color, false, outline_thickness)

			"don": # Cross
				var o = s/2
				draw_line(Vector2(x - o, y - o), Vector2(x + o, y + o), color, outline_thickness)
				draw_line(Vector2(x - o, y + o), Vector2(x + o, y - o), color, outline_thickness)

			"chaka": # Triangle
				var pts = [
					Vector2(x, y - s/2),
					Vector2(x - s/2, y + s/2),
					Vector2(x + s/2, y + s/2)
				]
				draw_colored_polygon(pts, Color(0.2,0.2,0.2))
				draw_polyline(pts + [pts[0]], color, outline_thickness)

	# ---------------- XBOX LETTER SYMBOLS ----------------
	func _draw_xbox(pos: Vector2, input_type: String) -> void:
		var font: Font = get_theme_default_font()
		var fs: int = int(round(shape_size * parent_ref.xbox_font_size_multiplier))
		var x = pos.x - fs * 0.33
		var y = pos.y + fs * 0.33

		var text := ""
		var col := Color.WHITE

		match input_type:
			"pata": text = "X"; col = parent_ref.xbox_color_x
			"pon":  text = "B"; col = parent_ref.xbox_color_b
			"don":  text = "A"; col = parent_ref.xbox_color_a
			"chaka": text = "Y"; col = parent_ref.xbox_color_y

			_: text = "?"

		draw_string(font, Vector2(x, y), text, HORIZONTAL_ALIGNMENT_LEFT, -1, fs, col)

# ---------------- MAIN SETUP ----------------
func _ready() -> void:
	for c in get_children():
		c.queue_free()

	var vbox := VBoxContainer.new()
	vbox.name = "CommandsVBox"
	add_child(vbox)

	for cmd_name in commands.keys():
		var sequence: Array = commands[cmd_name]

		var row := HBoxContainer.new()
		row.custom_minimum_size = Vector2(0, shape_size + 8)
		vbox.add_child(row)

		var preview := ShapesPreview.new()
		preview.sequence = sequence.duplicate()
		preview.shape_size = shape_size
		preview.spacing = shape_spacing
		preview.outline_thickness = outline_thickness
		preview.shape_colors = shape_colors
		preview.parent_ref = self
		preview._update_min_size()
		row.add_child(preview)

		var spacer := Control.new()
		spacer.custom_minimum_size = Vector2(label_margin_left, 0)
		row.add_child(spacer)

		var lbl := Label.new()
		lbl.text = cmd_name
		if label_font:
			lbl.add_theme_font_override("font", label_font)
		lbl.add_theme_color_override("font_color", label_color)
		row.add_child(lbl)

		var row_sp := Control.new()
		row_sp.custom_minimum_size = Vector2(0, row_spacing)
		vbox.add_child(row_sp)
