extends RefCounted

const TEMPLATE := """
## A reactive _WRAPPING_.
class_name _CLASS_
extends Reactive

## The [_WRAPPING_] value of this _CLASS_.
var value: _WRAPPING_ : set = _set_value

func _set_value(new_value: _WRAPPING_) -> _WRAPPING_:
	value = new_value
	value_changed.emit(self)
	return value

func _init(initial_value: _WRAPPING_, initial_owner: Reactive = null) -> void:
	super._init(initial_owner)
	value = initial_value
"""

static func create(classname: String, wrapping: String) -> String:
	var script := TEMPLATE
	script = (script
		.replace("_CLASS_", classname.to_pascal_case())
		.replace("_WRAPPING_", wrapping)
		.strip_edges(true, false)
	)
	return script
