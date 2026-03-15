extends VBoxContainer

@onready var CPicker: Control = find_parent("ColorPicker")
var hex_value: int = 0x000000


func _value_changed(new_color: ReactiveColor) -> void:
	if hex_value != new_color.value.to_rgba32():
		@warning_ignore("integer_division")
		$Edit.text = "%x" % (new_color.value.to_rgba32() / 0x100)


func _on_text_changed(new_text: String) -> void:
	if new_text.is_valid_hex_number():
		var hex: int = new_text.hex_to_int() * 0x100 + 0xff
		hex_value = hex
		CPicker.color.value = Color.hex(hex)
