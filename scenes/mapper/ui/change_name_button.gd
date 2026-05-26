extends Button

func _pressed() -> void:
	if State.client:
		var prompt_res := Prompts.new_fullscreen_prompt()
		if prompt_res.is_ok():
			var _prompt: PromptInstance = prompt_res.val()
			var info := preload("res://scenes/mapper/ui/change_name_prompt.tscn").instantiate()
			var line_edit: LineEdit = info.get_node("LineEdit")
			var button: Button = info.get_node("Button")
			button.pressed.connect(prompt_finish.bind(line_edit))
			line_edit.text_submitted.connect(prompt_finish.bind(line_edit))
			_prompt.add_child(info)
			
func prompt_finish(line_edit: LineEdit) -> void:
	if ISUtil.validate_rp_name(line_edit.text) or line_edit.text == "":
		State.client.send("change_rp_name", line_edit.text)
		Prompts.close_top_prompt()
	else:
		pass #show error
