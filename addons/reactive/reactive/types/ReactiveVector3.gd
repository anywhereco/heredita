## A reactive Vector3.
class_name ReactiveVector3
extends Reactive

## The [Vector3] value of this ReactiveVector3.
var value: Vector3 : set = _set_value

func _set_value(new_value: Vector3) -> Vector3:
	value = new_value
	value_changed.emit(self)
	return value

func _init(initial_value: Vector3, initial_owner: Reactive = null) -> void:
	super._init(initial_owner)
	value = initial_value
