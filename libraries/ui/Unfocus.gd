extends Control


func _input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.is_pressed() and event.button_index == 1:
		var evLocal := make_input_local(event)
		if !Rect2(Vector2(0, 0), size).has_point(evLocal.position as Vector2):
			release_focus()
