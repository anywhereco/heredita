extends Button

const NEW_ROOM_PROMPT = preload(
	"res://scenes/main_menu/pages/room_list/new_room/NewRoomPrompt.tscn"
)


func _pressed() -> void:
	var prompt_res := Prompts.new_fullscreen_prompt()
	if prompt_res.is_err():
		return
	var prompt: PromptInstance = prompt_res.val()
	prompt.add_child(NEW_ROOM_PROMPT.instantiate())
