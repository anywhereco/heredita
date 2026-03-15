class_name ReactiveColor
extends Reactive

var value: Color:
	set = _set_value


func _set_value(new_value: Color) -> Color:
	value = new_value
	value_changed.emit(self)
	return value


func _init(initial_value: Color, initial_owner: Reactive = null) -> void:
	super._init(initial_owner)
	value = initial_value


func deep_unconvert() -> Color:
	return value
