extends HBoxContainer

@onready var CPicker: Control = find_parent("ColorPicker")


func _value_changed(new_color: ReactiveColor) -> void:
	$R.set_value_no_signal(new_color.value.r * 255)
	$G.set_value_no_signal(new_color.value.g * 255)
	$B.set_value_no_signal(new_color.value.b * 255)


func _r_changed(value: float) -> void:
	@warning_ignore("unsafe_call_argument")
	var color: Color = Color(value / 255, $G.value / 255, $B.value / 255)
	CPicker.color.value = color


func _g_changed(value: float) -> void:
	@warning_ignore("unsafe_call_argument")
	var color: Color = Color($R.value / 255, value / 255, $B.value / 255)
	CPicker.color.value = color


func _b_changed(value: float) -> void:
	@warning_ignore("unsafe_call_argument")
	var color: Color = Color($R.value / 255, $G.value / 255, value / 255)
	CPicker.color.value = color
