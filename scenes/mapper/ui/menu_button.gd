extends Button


func _pressed() -> void:
	var prompt_res := Prompts.new_fullscreen_prompt()
	if prompt_res.is_ok():
		var prompt: PromptInstance = prompt_res.val()
		prompt.hide_panel()
		var menu := preload("res://scenes/mapper/ui/pause_menu/menu.tscn").instantiate()
		prompt.add_child(menu)
