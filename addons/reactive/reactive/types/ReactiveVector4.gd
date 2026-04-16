## A reactive Vector4.
class_name ReactiveVector4
extends Reactive

## The [Vector4] value of this ReactiveVector4.
var value: Vector4 : set = _set_value

func _set_value(new_value: Vector4) -> Vector4:
	value = new_value
	value_changed.emit(self)
	return value

func _init(initial_value: Vector4, initial_owner: Reactive = null) -> void:
	super._init(initial_owner)
	value = initial_value
