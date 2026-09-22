extends Button

func _pressed() -> void:
	close()

func _unhandled_key_input(event: InputEvent) -> void:
	if event.is_action_pressed("pause_menu"):
		close.call_deferred() 
		# We call this deferred so close is only called at the end
		# of the frame, i.e. after the UI's menu button tries to open the menu

func close() -> void:
	UIRoot._instance.menu_button.pause_menu_open = false
	Prompts.close_top_prompt()
