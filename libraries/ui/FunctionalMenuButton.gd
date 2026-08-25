## A MenuButton with a better interface :D
class_name FunctionalMenuButton
extends MenuButton

var callables: Dictionary[int, Callable]

func _ready() -> void:
	get_popup().id_pressed.connect(func(id: int) -> void: callables.get(id).call())

## Creates a new entry.
func entry(name: String, icon: Texture2D, action: Callable, key: Key = KEY_NONE) -> void:
	var id := get_popup().item_count
	get_popup().add_icon_item(icon, tr(name), id, key)
	callables[id] = action

## Creates a seperator element.
func seperator(name: String = "") -> void:
	var id := get_popup().item_count
	get_popup().add_separator(name, id)
