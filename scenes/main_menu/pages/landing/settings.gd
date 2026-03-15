extends Button


func _pressed() -> void:
	var prompt_res := Prompts.new_fullscreen_prompt()
	if prompt_res.is_ok():
		var prompt: PromptInstance = prompt_res.val()
		var settings := preload("res://scenes/_settings/settings.tscn").instantiate()
		prompt.add_child(settings)
