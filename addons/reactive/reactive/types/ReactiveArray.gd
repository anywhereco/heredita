## A reactive Array, with utility methods.
class_name ReactiveArray
extends Reactive

## The [Array] value of this ReactiveArray. [br] [br]
## [b]Note:[/b] Arrays are reference-based, so you may need to occasionally call [method Reactive.emit] if you do not re-set the [code]value[/code].
var value: Array:
	set = _set_value


## Create a ReactiveArray from elements.
static func of_elements(...args: Array) -> ReactiveArray:
	return new(args)


## Create a ReactiveArray from elements with a pre-set owner.
static func of_elements_with_owner(initial_owner: Reactive, ...args: Array) -> ReactiveArray:
	return new(args, initial_owner)


func _set_value(new_value: Array) -> Array:
	value = new_value
	value_changed.emit(self)
	return value


func _init(initial_value: Array, initial_owner: Reactive = null) -> void:
	super._init(initial_owner)
	value = initial_value


## Get the value at the index, equivalent to [code]array[index][/code].
func get_at(index: int) -> Variant:
	return value[index]


## Sets the value at the index, equivalent to [code]array[index] = value[/code].
func set_at(index: int, new_value: Variant) -> void:
	value[index] = new_value
	value_changed.emit(self)


## Appends a value to the end of the ReactiveArray.
func append(other: Variant) -> void:
	value.append(other)
	value_changed.emit(self)


## Appends another array to the end of this ReactiveArray.
func append_array(array: Array) -> void:
	value.append_array(array)
	value_changed.emit(self)


## Assigns elements of another array into the ReactiveArray.
func assign(array: Array) -> void:
	value.assign(array)
	value_changed.emit(self)


## Clears the ReactiveArray.
func clear() -> void:
	value.clear()
	value_changed.emit(self)


## Removes the first instance of [code]val[/code] from this ReactiveArray.
func erase(val: Variant) -> void:
	value.erase(val)
	value_changed.emit(self)


## Inserts [code]val[/code] into this ReactiveArray before position [code]position[/code].
func insert(position: int, val: Variant) -> void:
	value.insert(position, val)
	value_changed.emit(self)


## Removes and returns the element of the ReactiveArray at index [code]position[/code], or null if empty.
func pop_at(position: int) -> Variant:
	var tmp: Variant = value.pop_at(position)
	value_changed.emit(self)
	return tmp


## Removes and returns the last element of the ReactiveArray, or null if empty.
func pop_back() -> Variant:
	var tmp: Variant = value.pop_back()
	value_changed.emit(self)
	return tmp


## Removes and returns the first element of the ReactiveArray, or null if empty.
func pop_front() -> Variant:
	var tmp: Variant = value.pop_front()
	value_changed.emit(self)
	return tmp


## Removes the element of the ReactiveArray at index [code]position[/code], erroring out if it is out of bounds.
func remove_at(position: int) -> void:
	value.remove_at(position)
	value_changed.emit(self)


## Shuffles the ReactiveArray.
func shuffle() -> void:
	value.shuffle()
	value_changed.emit(self)


## Sorts the ReactiveArray.
func sort() -> void:
	value.sort()
	value_changed.emit(self)


## Sorts the ReactiveArray with the method specified in the Callable. [br] [br]
## The function should return true if the first element should be moved before the second one, otherwise it should return false.
func sort_custom(sort_method: Callable) -> void:
	value.sort_custom(sort_method)
	value_changed.emit(self)
