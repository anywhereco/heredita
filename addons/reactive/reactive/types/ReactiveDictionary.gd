class_name ReactiveDictionary
extends Reactive

var value: Dictionary:
	set = _set_value


func _set_value(new_value: Dictionary) -> Dictionary:
	value = new_value
	value_changed.emit(self)
	return value


func _init(initial_value: Dictionary, initial_owner: Reactive = null) -> void:
	super._init(initial_owner)
	value = initial_value


func getv(index: Variant, fallback: Variant = null) -> Variant:
	if value.has(index) or fallback == null:  # We want to error out if no fallback is provided
		return value[index]
	return fallback


func get_or_add(index: Variant, fallback: Variant = null) -> Variant:
	if fallback is Reactive:
		fallback._set_owner(self)
	return value.get_or_add(index, fallback)


func setv(index: Variant, new_value: Variant) -> void:
	if new_value is Reactive:
		new_value._set_owner(self)
	value[index] = new_value
	value_changed.emit(self)


func keys() -> Array:
	return value.keys()


func hash() -> int:
	return value.hash()


func size() -> int:
	return value.size()


func has(index: Variant) -> bool:
	return value.has(index)


func assign(dict: Dictionary) -> void:
	for key in dict:
		if dict[key] is Reactive:
			dict[key]._set_owner(self)
	value.assign(dict)
	value_changed.emit(self)


func clear() -> void:
	value.clear()
	value_changed.emit(self)


func erase(val: Variant) -> void:
	value.erase(val)
	value_changed.emit(self)


func sort() -> void:
	value.sort()
	value_changed.emit(self)


func deep_unconvert() -> Array:
	var dict = {}
	for i in value:
		if value[i] is Reactive:
			dict[i] = value[i].deep_unconvert()
		else:
			dict[i] = value[i]
	return dict
