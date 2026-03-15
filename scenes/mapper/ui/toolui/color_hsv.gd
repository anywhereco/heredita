extends HBoxContainer

@onready var CPicker: Control = find_parent("ColorPicker")

var sv_rect_dot: Vector2 = Vector2(0, 0)


func _process(_delta: float) -> void:
	$SVRect/Dot.position = sv_rect_dot * $SVRect.size - $SVRect/Dot.size / 2


func _value_changed(new_color: ReactiveColor) -> void:
	if new_color.value.s > 0 and new_color.value.v > 0:
		$Hue.set_value_no_signal(new_color.value.h * 360)
	@warning_ignore("unsafe_call_argument")
	var pure_hue: Color = Color.from_hsv($Hue.value / 360, 1.0, 1.0)
	$SVRect.material.set_shader_parameter("hue", pure_hue)
	sv_rect_dot = Vector2(new_color.value.s, 1 - new_color.value.v)
	$SVRect/Dot.position = sv_rect_dot * $SVRect.size - $SVRect/Dot.size / 2


func _sv_gui_input(event: InputEvent) -> void:
	var pos: Vector2
	if event is InputEventMouseButton and event.pressed:
		pos = event.position
	elif event is InputEventMouseMotion and event.button_mask:
		pos = event.position
	else:
		return

	sv_rect_dot = (pos / $SVRect.size).clampf(0.0, 1.0)
	var x_fraction: float = sv_rect_dot.x
	var y_fraction: float = sv_rect_dot.y
	@warning_ignore("unsafe_call_argument")
	var color: Color = Color.from_hsv($Hue.value / 360, x_fraction, 1 - y_fraction)
	CPicker.color.value = color


func _hue_changed(value: float) -> void:
	var color: Color = Color.from_hsv(value / 360, sv_rect_dot.x, 1 - sv_rect_dot.y)
	CPicker.color.value = color
