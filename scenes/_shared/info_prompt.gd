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
