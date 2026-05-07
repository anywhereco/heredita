extends Window


func _notification(what: int) -> void:
	if State:  # If the State autoload is freed, we're probably shutting down anyway
		State.display._root_window_notifications(what)
