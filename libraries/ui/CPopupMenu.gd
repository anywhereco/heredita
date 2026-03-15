extends PanelContainer
class_name CPopupMenu
#C is for Control

#do NOT mess with these individually; they need to be in sync to work properly
var item_list: ItemList
var item_actions := []


func _init() -> void:
	item_list = ItemList.new()
	item_list.auto_height = true
	item_list.auto_width = true
	item_list.item_selected.connect(
		func(i: int) -> void:
			item_actions[i].call()
			queue_free()
	)
	add_child(item_list)


func add_item(item: String, callback: Callable) -> void:
	item_list.add_item(item)
	item_actions.append(callback)


func item_count() -> int:
	return item_list.item_count


func display() -> void:
	TopLevel.get_ui().add_child(self)


func align(node: CanvasItem) -> void:
	global_position = node.global_position
	if node is Control:
		global_position.y -= node.get_rect().size.y


func align_bottom(node: CanvasItem) -> void:
	global_position = node.global_position
	(func() -> void: global_position.y -= item_list.get_rect().size.y).call_deferred()


func _input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.is_pressed() and event.button_index == 1:
		var evLocal := make_input_local(event)
		if !Rect2(Vector2(0, 0), size).has_point(evLocal.position as Vector2):
			queue_free()
