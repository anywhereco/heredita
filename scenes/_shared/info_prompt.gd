extends Node
class_name InfoPrompt


static func prompt(description: String, button_text: String = "common/ok") -> void:
	var prompt_res := Prompts.new_fullscreen_prompt()
	if prompt_res.is_ok():
		var _prompt: PromptInstance = prompt_res.val()
		var info := preload("res://scenes/_shared/info_prompt.tscn").instantiate()
		info.get_node("Label").text = TranslationServer.translate(description)
		info.get_node("Button").text = TranslationServer.translate(button_text)
		info.get_node("Button").pressed.connect(Prompts.close_top_prompt)
		_prompt.add_child(info)


static func custom_prompt(description: String, buttons: Dictionary) -> void:
	var prompt_res := Prompts.new_fullscreen_prompt()
	if prompt_res.is_ok():
		var _prompt: PromptInstance = prompt_res.val()
		var info := preload("res://scenes/_shared/custom_info_prompt.tscn").instantiate()
		info.get_node("Label").text = TranslationServer.translate(description)
		for text: String in buttons:
			var button := Button.new()
			button.text = TranslationServer.translate(text)
			@warning_ignore("unsafe_call_argument")
			button.pressed.connect(buttons[text])
			info.get_node("Buttons").add_child(button)
		_prompt.add_child(info)
