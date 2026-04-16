## A reactive Vector2.
class_name ReactiveVector2
extends Reactive

## The [Vector2] value of this ReactiveVector2.
var value: Vector2 : set = _set_value

func _set_value(new_value: Vector2) -> Vector2:
	value = new_value
	value_changed.emit(self)
	return value

func _init(initial_value: Vector2, initial_owner: Reactive = null) -> void:
	super._init(initial_owner)
	value = initial_value
