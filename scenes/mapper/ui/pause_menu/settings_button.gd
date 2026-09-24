extends Button


func _pressed() -> void:
	var menu_button: UIMenuButton = UIRoot._instance.menu_button
	Prompts.close_top_prompt()
	var prompt_res := Prompts.new_fullscreen_prompt()
	if prompt_res.is_ok():
		var prompt: PromptInstance = prompt_res.val()
		prompt.prompt_closed.connect(menu_button.settings_prompt_closed)
		var settings := preload("res://scenes/_settings/settings.tscn").instantiate()
		prompt.add_child(settings)
		#VirtualMouse._instance.enabled = false
		#prompt.prompt_closed.connect(VirtualMouse._instance.set.bind("enabled",true))
	else:
		menu_button.pause_menu_open = false
