extends Node

@export var character: CharacterBody2D  # set this in the editor (Player node reference)

func _ready():
	add_to_group("battle")

# ==========================
# Action methods
# ==========================
func charge():
	print("charge")
	if character:
		character.charge_up()

func attack():
	print("attack.")
	if not character:
		return

	# ✅ Check if enough charges before executing
	if character.current_charges < 2:
		print("❌ Not enough charges to attack! (Needs 2, has %d)" % character.current_charges)
		return

	character.attack()

func heal():
	print("heal")
	if not character:
		return

	# ✅ Check if enough charges before executing
	if character.current_charges < 3:
		print("❌ Not enough charges to heal! (Needs 3, has %d)" % character.current_charges)
		return

	character.heal(3)

func shield():
	print("Activating shield.")
	# (You can add charge cost here later if needed)

func retreat():
	print("retreat")
	if character:
		character.start_retreat()

# ==========================
# Command router
# ==========================
func process_command(action: String) -> void:
	match action:
		"charge":
			charge()
		"attack":
			attack()
		"shield":
			shield()
		"heal":
			heal()
		"retreat":
			retreat()
		_:
			print("❌ Unknown action:", action)
