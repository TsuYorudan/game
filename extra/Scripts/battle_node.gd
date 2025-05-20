extends Node

# Export the reference to the CharacterBody2D node
@export var character: CharacterBody2D  # This will be set in the editor

func _ready():
	# Add this node to the "battle" group
	add_to_group("battle")

# Declare the possible actions
func march():
	print("march")
	if character:
		character.start_marching()  # Call the start_marching method on the character node

func attack():
	print("attack.")
	if character:
		character.attack()
	# Add counter-attack logic here

func shield():
	print("Activating shield.")
	# Add shield logic here

func heal():
	print("heal")
	if character:
		character.heal(3)
	
func retreat():
	print("retreat")
	if character:
		character.start_retreat()  # Call the start_retreat method to move the character left

# Method to process the command sent from the rhythm system
func process_command(action: String) -> void:
	match action:
		"march":
			march()
		"attack":
			attack()
		"shield":
			shield()
		"heal":
			heal()
		"retreat":
			retreat()  # Now calls retreat
		_:
			print("❌ Unknown action: ", action)
