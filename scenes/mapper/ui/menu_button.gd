class_name UIMenuButton
extends Button

var pause_menu_open: bool = false

func _pressed() -> void:
	open_pause_menu()

func _unhandled_key_input(event: InputEvent) -> void:
	if event.is_action_pressed("pause_menu"):
		open_pause_menu()

func open_pause_menu() -> void:
	if pause_menu_open:
		return
	var prompt_res := Prompts.new_fullscreen_prompt()
	if prompt_res.is_ok():
		pause_menu_open = true
		var prompt: PromptInstance = prompt_res.val()
		prompt.hide_panel()
		var menu := preload("res://scenes/mapper/ui/pause_menu/menu.tscn").instantiate()
		prompt.add_child(menu)


func settings_prompt_closed() -> void:
	pause_menu_open = false
