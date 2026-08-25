## A MenuButton with a functional interface to make the PopupMenu.
class_name FunctionalMenuButton
extends MenuButton

var callables: Dictionary[int, Callable]

func _ready() -> void:
	get_popup().id_pressed.connect(func(id: int) -> void: callables.get(id).call())

## Creates a new entry for the PopupMenu with the specified name and string.
## This calls the [code]action[/code] when it is pressed.
@warning_ignore("shadowed_variable_base_class")
func entry(name: String, icon: Texture2D, action: Callable, key: Key = KEY_NONE) -> void:
	var id := get_popup().item_count
	get_popup().add_icon_item(icon, tr(name), id, key)
	callables[id] = action

## Creates a seperator element to split buttons into groups.
## A label can optionally be provided, which will appear at the center of the separator.
@warning_ignore("shadowed_variable_base_class")
func seperator(label: String = "") -> void:
	var id := get_popup().item_count
	get_popup().add_separator(tr(label), id)
