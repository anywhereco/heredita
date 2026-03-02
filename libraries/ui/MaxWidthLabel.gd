#thanks Adriaan de Jongh
class_name MaxWidthLabel
extends Label

@export var max_width: float


func _ready() -> void:
	resized.connect(_on_label_resized)
	autowrap_mode = TextServer.AUTOWRAP_OFF
	custom_minimum_size = Vector2.ZERO
	_on_label_resized()


func set_text_and_adjust_width(_text: String) -> void:
	text = _text
	autowrap_mode = TextServer.AUTOWRAP_OFF
	custom_minimum_size = Vector2.ZERO


func _on_label_resized() -> void:
	if size.x > max_width:
		autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		custom_minimum_size = Vector2(max_width, 0.0)
