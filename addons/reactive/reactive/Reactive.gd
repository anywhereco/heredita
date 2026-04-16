@icon("../Reactive.svg")
## A Resource with a way to update owner nodes.
extends Resource
class_name Reactive

## Emitted when the value of the Reactive has changed. You can safely cast this to the Reactive of the type that has changed.
signal value_changed(reactive: Reactive)

## The owner of this Reactive. [br]
## Value changes will be propagated to the owner.
var owner: Reactive:
	set = _set_owner


func _set_owner(new_owner: Reactive) -> void:
	if owner != null:
		value_changed.disconnect(owner._propagate)
	owner = new_owner
	if owner != null:
		value_changed.connect(owner._propagate)


func _init(init_owner: Reactive = null) -> void:
	owner = init_owner


func _propagate(_other: Reactive = null) -> void:
	value_changed.emit(self)

## Emit that the value of this Reactive has changed. Can be useful for manual modifications.
func emit() -> void:
	value_changed.emit(self)

## Create a GDScript resource that wraps 
