extends Button


func _pressed() -> void:
	if State.client:
		State.client.close()
	VirtualMouse._instance.set_action_tool(VirtualMouse.Action.DEFAULT)
	get_tree().change_scene_to_file("res://scenes/main_menu/main.tscn")
