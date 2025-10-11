extends Control
class_name CommandCheatSheet

# Commands -> sequence of inputs (use "pata","pon","don","chaka")
@export var commands: Dictionary = {
	"Attack": ["pata", "pata", "pon", "pon"],
	"charge":  ["pon", "pon", "pata", "don"],
	"Heal":   ["chaka", "chaka", "pata", "pon"],
	"Retreat":["pon", "pata", "pon", "pata"]
}

# Visual params (tweak in inspector)
@export var shape_size: float = 20.0
@export var outline_thickness: float = 3.0
@export var shape_spacing: float = 8.0
@export var row_spacing: float = 8.0
@export var label_margin_left: float = 12.0
@export var label_font: Font
@export var label_color: Color = Color(1,1,1)

var shape_colors: Dictionary = {
	"pata": Color(1, 1, 1),
	"pon": Color(1, 1, 1),
	"don": Color(1, 1, 1),
	"chaka": Color(1, 1, 1)
}

# -------- ShapesPreview control (inline class) ----------
class ShapesPreview:
	extends Control

	var sequence: Array = []
	var shape_size: float = 20.0
	var spacing: float = 8.0
	var outline_thickness: float = 3.0
	var shape_colors: Dictionary = {}

	func _ready() -> void:
		_update_min_size()
		queue_redraw()

	func _update_min_size() -> void:
		# width should account for spacing only between items
		var width = max(1, sequence.size()) * shape_size + max(0, sequence.size() - 1) * spacing
		set_custom_minimum_size(Vector2(width, shape_size + 8))

	func _notification(what: int) -> void:
		if what == NOTIFICATION_RESIZED:
			queue_redraw()

	func _draw() -> void:
		var x = shape_size * 0.5
		var y = (shape_size + 8.0) * 0.5
		for input_type in sequence:
			_draw_input_shape(Vector2(x, y), input_type)
			x += shape_size + spacing

	func _draw_input_shape(pos: Vector2, input_type: String) -> void:
		var s = shape_size
		var x = pos.x
		var y = pos.y
		var white_fill = Color(0,0,0,1)
		var color = shape_colors.get(input_type, Color(0.8,0.8,0.8))

		match input_type:
			"pata":
				draw_rect(Rect2(x - s/2, y - s/2, s, s), white_fill)
				draw_rect(Rect2(x - s/2, y - s/2, s, s), color, false, outline_thickness)
			"pon":
				draw_circle(Vector2(x, y), s/2, white_fill)
				draw_circle(Vector2(x, y), s/2, color, false, outline_thickness)
			"don":
				var offset = s * 0.5
				var p1 = Vector2(x - offset, y - offset)
				var p2 = Vector2(x + offset, y + offset)
				var p3 = Vector2(x - offset, y + offset)
				var p4 = Vector2(x + offset, y - offset)
				# white fill-ish cross
				draw_line(p1, p2, white_fill, outline_thickness)
				draw_line(p3, p4, white_fill, outline_thickness)
				# colored outline
				draw_line(p1, p2, color, outline_thickness + 1)
				draw_line(p3, p4, color, outline_thickness + 1)
			"chaka":
				var points = [
					Vector2(x, y - s/2),
					Vector2(x - s/2, y + s/2),
					Vector2(x + s/2, y + s/2)
				]
				draw_colored_polygon(points, white_fill)
				draw_polyline(points + [points[0]], color, outline_thickness)
			_:
				# fallback small circle
				draw_circle(Vector2(x, y), 3, color)

# -------- CommandCheatSheet main setup ----------
func _ready() -> void:
	# Remove existing children if any (useful while iterating)
	for c in get_children():
		c.queue_free()

	# Parent container
	var vbox := VBoxContainer.new()
	vbox.name = "CommandsVBox"
	vbox.custom_minimum_size = Vector2(0, 0)
	add_child(vbox)

	# Build each command row
	for command_name in commands.keys():
		# explicit typed variable to avoid inference warnings
		var sequence: Array = commands[command_name]

		# HBox for the row
		var row := HBoxContainer.new()
		row.custom_minimum_size = Vector2(0, shape_size + 8)
		vbox.add_child(row)

		# Shapes preview instance
		var shapes := ShapesPreview.new()
		shapes.sequence = sequence.duplicate()
		shapes.shape_size = shape_size
		shapes.spacing = shape_spacing
		shapes.outline_thickness = outline_thickness
		shapes.shape_colors = shape_colors
		shapes._update_min_size()
		row.add_child(shapes)

		# spacer between shapes and label
		var spacer := Control.new()
		spacer.custom_minimum_size = Vector2(label_margin_left, 0)
		row.add_child(spacer)

		# Label
		var lbl := Label.new()
		lbl.text = str(command_name)
		if label_font:
			lbl.add_theme_font_override("font", label_font)
		lbl.add_theme_color_override("font_color", label_color)
		# we avoid setting vertical alignment constants to prevent compatibility issues;
		# the HBoxContainer row height and label margins will do the job
		row.add_child(lbl)

		# row spacing (simple vertical spacer)
		var row_sp := Control.new()
		row_sp.custom_minimum_size = Vector2(0, row_spacing)
		vbox.add_child(row_sp)

	# initial draw
	queue_redraw()

# Optional helper API to highlight a command by name briefly
func highlight_command(name: String, duration: float = 0.6) -> void:
	var vbox: VBoxContainer = null
	if has_node("CommandsVBox"):
		vbox = $CommandsVBox
	else:
		return
	
	for child in vbox.get_children():
		if child is HBoxContainer:
			var lbl_node = child.get_child(child.get_child_count() - 1)
			if lbl_node is Label and lbl_node.text == name:
				var orig: Color = lbl_node.get_theme_color("font_color")
				lbl_node.add_theme_color_override("font_color", Color(1, 1, 1)) # 🔹 Highlight white
				await get_tree().create_timer(duration).timeout
				lbl_node.add_theme_color_override("font_color", orig)
				return
