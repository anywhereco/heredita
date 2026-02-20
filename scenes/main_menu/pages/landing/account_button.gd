extends Button

const LOGIN_SIGNUP_PROMPT = preload("res://scenes/main_menu/pages/landing/LoginSignupPrompt.tscn")

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	if State.user and State.user.initialized:
		logged_in()
		return
	State.user.user_initialized.connect(logged_in)

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
	
func logged_in() -> void:
	disabled = true
	text = "Your account  "
