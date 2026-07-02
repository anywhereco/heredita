extends Button

func _ready() -> void:
	if not State.player.rank >= UserEnums.Rank.MODERATOR:
		hide()

func _pressed() -> void:
	if State.client:
		var prompt_res := Prompts.new_fullscreen_prompt()
		if prompt_res.is_ok():
			var _prompt: PromptInstance = prompt_res.val()
			var info := preload("res://scenes/mapper/ui/mod_tools_prompt.tscn").instantiate()
			var button: Button = info.get_node("Button")
			button.pressed.connect(State.client.send.bind("mod:roomblock_creator"))
			_prompt.add_child(info)
