extends Control

@onready var input_progress: HBoxContainer = $InputProgress

var total_inputs := 4
var current_inputs := 0

func _ready():
	# Initialize all labels with "_"
	update_input_progress(0)

# Call this to update the UI with how many inputs done
func update_input_progress(current: int) -> void:
	current_inputs = clamp(current, 0, total_inputs)
	for i in range(total_inputs):
		var label = input_progress.get_child(i) as Label
		if i < current_inputs:
			label.text = "X"
		else:
			label.text = "_"

# For testing: press keys 1-4 to simulate inputs
func _input(event):
	if event is InputEventKey and event.pressed:
		if event.scancode == KEY_1:
			update_input_progress(1)
		elif event.scancode == KEY_2:
			update_input_progress(2)
		elif event.scancode == KEY_3:
			update_input_progress(3)
		elif event.scancode == KEY_4:
			update_input_progress(4)
