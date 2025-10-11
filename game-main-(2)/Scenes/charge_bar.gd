extends ProgressBar
class_name ChargeUI

@export var max_charges: int = 6
@export var charge_spacing: float = 4.0
@export var charge_height: float = 16.0
@export var fill_color: Color = Color(1, 1, 1)
@export var empty_color: Color = Color(0.2, 0.2, 0.2)
@export var divider_color: Color = Color(0, 0, 0)

var current_charges: int = 0

func _ready():
	min_value = 0
	max_value = max_charges
	value = current_charges
	queue_redraw()


	# Connect to player signals
	var player = get_tree().get_first_node_in_group("player")
	if player:
		player.connect("charges_changed", Callable(self, "_on_charges_changed"))

func _on_charges_changed(charges: int):
	current_charges = charges
	value = current_charges
	queue_redraw()


func _draw():
	var total_width = size.x
	var slot_width = (total_width - (max_charges - 1) * charge_spacing) / max_charges
	var y = (size.y - charge_height) / 2

	for i in range(max_charges):
		var x = i * (slot_width + charge_spacing)
		var color = fill_color if i < current_charges else empty_color
		draw_rect(Rect2(x, y, slot_width, charge_height), color)

		# Draw divider lines between charges
		if i < max_charges - 1:
			draw_line(
				Vector2(x + slot_width + charge_spacing / 2, y),
				Vector2(x + slot_width + charge_spacing / 2, y + charge_height),
				divider_color,
				2
			)
