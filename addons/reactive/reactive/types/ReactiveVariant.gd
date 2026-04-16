## A reactive Variant.
class_name ReactiveVariant
extends Reactive

## The [Variant] value of this ReactiveVariant.
var value: Variant : set = _set_value

func _set_value(new_value: Variant) -> Variant:
	value = new_value
	value_changed.emit(self)
	return value

func _init(initial_value: Variant, initial_owner: Reactive = null) -> void:
	super._init(initial_owner)
	value = initial_value
