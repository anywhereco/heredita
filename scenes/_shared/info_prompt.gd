extends Node
class_name InfoPrompt

static func prompt(description: String, button_text: String = "OK") -> void:
	var prompt_res := Prompts.new_fullscreen_prompt()
	if prompt_res.is_ok():
		var prompt: PromptInstance = prompt_res.val()
		var info := preload("res://scenes/_shared/info_prompt.tscn").instantiate()
		info.get_node("Label").text = description
		info.get_node("Button").text = button_text
		info.get_node("Button").pressed.connect(Prompts.close_top_prompt)
		prompt.add_child(info)

static func custom_prompt(description: String, buttons: Dictionary) -> void:
	var prompt_res := Prompts.new_fullscreen_prompt()
	if prompt_res.is_ok():
		var prompt: PromptInstance = prompt_res.val()
		var info := preload("res://scenes/_shared/custom_info_prompt.tscn").instantiate()
		info.get_node("Label").text = description
		for text: String in buttons:
			var button := Button.new()
			button.text = text
			button.pressed.connect(buttons[text])
			info.get_node("Buttons").add_child(button)
		prompt.add_child(info)
