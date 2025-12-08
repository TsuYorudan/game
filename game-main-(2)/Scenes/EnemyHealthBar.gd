extends ProgressBar
class_name EnemyHealthBar

@export var enemy: Node
@export var delay_speed: float = 60.0
@export var heal_speed: float = 100.0
@export var delay_color: Color = Color(1, 0, 0, 0.7)
@export var main_color: Color = Color(0.1, 1.0, 0.1)
@export var shake_magnitude: float = 5.0
@export var shake_duration: float = 0.3
@export var shake_ease: float = 8.0  # higher = faster smoothing

var delayed_value: float
var target_value: float
var delay_bar: ColorRect

var shaking: bool = false
var shake_time: float = 0.0
var original_position: Vector2
var shake_offset: Vector2 = Vector2.ZERO

func _ready():
	if enemy:
		enemy.connect("hpchange", Callable(self, "_on_enemy_hpchange"))
		await enemy.ready
		value = enemy.current_hp * 100.0 / enemy.max_hp
		delayed_value = value
		target_value = value
		_create_delay_bar()
		_create_main_bar_style()
		original_position = position
	else:
		print("No enemy assigned!")

func _create_delay_bar():
	delay_bar = ColorRect.new()
	delay_bar.color = delay_color
	delay_bar.anchor_left = 0
	delay_bar.anchor_top = 0
	delay_bar.anchor_right = 0
	delay_bar.anchor_bottom = 1
	delay_bar.size_flags_horizontal = Control.SIZE_FILL
	delay_bar.size_flags_vertical = Control.SIZE_FILL
	add_child(delay_bar)
	move_child(delay_bar, 0)
	delay_bar.visible = false
	delay_bar.position = Vector2.ZERO

func _create_main_bar_style():
	var style = StyleBoxFlat.new()
	style.bg_color = main_color
	add_theme_stylebox_override("fg", style)

func _process(delta):
	# Animate delayed bar
	if delayed_value > value:
		delayed_value = max(value, delayed_value - delay_speed * delta)
		_update_delay_bar()
		if delayed_value <= value:
			delay_bar.visible = false

	# Animate main bar towards target_value
	if abs(value - target_value) > 0.01:
		if value < target_value:
			value = min(value + heal_speed * delta, target_value)
		else:
			value = max(value - heal_speed * delta, target_value)

	# Handle shaking with easing
	if shaking:
		shake_time -= delta
		if shake_time > 0:
			var target_offset = Vector2(
				randf_range(-shake_magnitude, shake_magnitude),
				randf_range(-shake_magnitude, shake_magnitude)
			)
			shake_offset = shake_offset.lerp(target_offset, shake_ease * delta)
			position = original_position + shake_offset
			if delay_bar:
				delay_bar.position = Vector2(shake_offset.x, shake_offset.y)
		else:
			position = original_position
			if delay_bar:
				delay_bar.position = Vector2.ZERO
			shaking = false
			shake_offset = Vector2.ZERO

func _update_delay_bar():
	var percent = delayed_value / max_value
	delay_bar.size.x = percent * size.x

func update_bar():
	if not enemy:
		return
	var new_target = enemy.current_hp * 100.0 / enemy.max_hp
	if new_target < value:
		delay_bar.visible = true
		delayed_value = value
		_start_shake()
	target_value = new_target

func _start_shake():
	shaking = true
	shake_time = shake_duration

func _on_enemy_hpchange():
	update_bar()
