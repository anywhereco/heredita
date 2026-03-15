class_name ReactiveImage
extends Reactive

var value: Image:
	set = _set_value


func _set_value(new_value: Image) -> Image:
	value = new_value
	value_changed.emit(self)
	return value


func _init(initial_value: Image, initial_owner: Reactive = null) -> void:
	super._init(initial_owner)
	value = initial_value


func deep_unconvert() -> Image:
	return value
