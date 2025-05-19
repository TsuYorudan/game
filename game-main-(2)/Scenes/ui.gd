extends Control

@onready var input_progress: HBoxContainer = $InputProgress
var total_inputs := 4
var current_inputs := 0

func update_input_progress() -> void:
	for i in range(total_inputs):
		var label := input_progress.get_child(i)
		if label is Label:
			if i < current_inputs:
				label.text = "O"
			else:
				label.text = "_"


func add_input() -> void:
	if current_inputs < total_inputs:
		current_inputs += 1
		update_input_progress()

func reset_input() -> void:
	current_inputs = 0
	update_input_progress()

func _ready() -> void:
	update_input_progress()
