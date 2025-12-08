extends Enemy
class_name Boss

@export var max_charges: int = 6
@export var boss_max_hp: int = 50 
var current_charges: int = 0


signal boss_charges_changed(current: int)

func _ready():
	super._ready()
	current_charges = 0
	max_hp = boss_max_hp
	current_hp = max_hp
	emit_signal("boss_charges_changed", current_charges)

func gain_charge(amount: int = 1) -> void:
	current_charges = min(max_charges, current_charges + amount)
	emit_signal("boss_charges_changed", current_charges)
	print("Boss gained", amount, "charge →", current_charges)

	if current_charges >= max_charges:
		trigger_special()
		current_charges = 0
		emit_signal("boss_charges_changed", current_charges)

# Called when max charge is reached — overridden by boss types
func trigger_special() -> void:
	print("⚠️ Boss special triggered (base). Override me.")
