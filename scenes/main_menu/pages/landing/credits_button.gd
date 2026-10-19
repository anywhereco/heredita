extends LinkButton



func _pressed() -> void:
	var prompt_res := Prompts.new_fullscreen_prompt()
	if prompt_res.is_ok():
		var prompt: PromptInstance = prompt_res.val()
		var settings := preload("res://scenes/main_menu/pages/landing/credits/CreditPopup.tscn").instantiate()
		prompt.add_child(settings)
