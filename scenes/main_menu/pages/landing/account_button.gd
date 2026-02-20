extends Button

const LOGIN_SIGNUP_PROMPT = preload("uid://opivht8lbmfs")

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta: float) -> void:
	pass

func _pressed() -> void:
	if State.user and State.user.initialized:
		return
	var pres := Prompts.new_fullscreen_prompt()
	if pres.is_err():
		return
	var prompt: PromptInstance = pres.val()
	prompt.hide_panel()
	prompt.add_child(LOGIN_SIGNUP_PROMPT.instantiate())
	
