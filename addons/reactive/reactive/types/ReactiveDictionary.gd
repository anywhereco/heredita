## A reactive Dictionary, with utility methods.
class_name ReactiveDictionary
extends Reactive

## The [Dictionary] value of this ReactiveDictionary. [br] [br]
## [b]Note:[/b] Dictionaries are reference-based, so you may need to occasionally call [method Reactive.emit] if you do not re-set the [code]value[/code].
var value: Dictionary:
	set = _set_value


func _set_value(new_value: Dictionary) -> Dictionary:
	value = new_value
	value_changed.emit(self)
	return value


func _init(initial_value: Dictionary, initial_owner: Reactive = null) -> void:
	super._init(initial_owner)
	value = initial_value


## Get the value at the key, equivalent to [code]dict[key][/code]. [br] [br]
## [b]Note:[/b] You may provide a fallback to be given instead of erroring.
func getv(key: Variant, fallback: Variant = null) -> Variant:
	if value.has(key) or fallback == null:
		return value[key]
	return fallback


## Get the value at the key, or adds it if it does not exist.
func get_or_add(key: Variant, fallback: Variant = null) -> Variant:
	if fallback is Reactive:
		fallback._set_owner(self)
	return value.get_or_add(key, fallback)


## Sets the value at the key, equivalent to [code]dict[key] = foo[/code]. [br] [br]
## [b]Note:[/b] This function will automatically set the owner of other Reactives to this one. 
## If this is undesired, set the [code]set_owner[/code] parameter to false.
func setv(key: Variant, new_value: Variant, set_owner: bool = true) -> void:
	if new_value is Reactive and set_owner:
		new_value._set_owner(self)
	value[key] = new_value
	value_changed.emit(self)


## Get all the keys in this ReactiveDictionary.
func keys() -> Array:
	return value.keys()
	

## Returns the hash of the ReactiveDictionary.
func hash() -> int:
	return value.hash()


## Returns the number of entries in the ReactiveDictionary.
func size() -> int:
	return value.size()


## Returns true if the ReactiveDictionary has the key.
func has(key: Variant) -> bool:
	return value.has(key)


## Assigns elements of a Dictionary into this ReactiveDictionary. [br] [br]
## [b]Note:[/b] This function will automatically set the owner of other Reactives to this one. 
## If this is undesired, set the [code]set_owner[/code] parameter to false.
func assign(dict: Dictionary, set_owner: bool = true) -> void:
	for key in dict:
		if dict[key] is Reactive:
			dict[key]._set_owner(self)
	value.assign(dict)
	value_changed.emit(self)


## Clear this ReactiveDictionary.
func clear() -> void:
	value.clear()
	value_changed.emit(self)


## Erase the key of the ReactiveDictionary.
func erase(key: Variant) -> bool:
	var retval := value.erase(key)
	value_changed.emit(self)
	return retval


## Sorts the ReactiveDictionary's keys in ascending order.
func sort() -> void:
	value.sort()
	value_changed.emit(self)
