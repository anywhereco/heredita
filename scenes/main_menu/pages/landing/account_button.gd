extends Button

const LOGIN_SIGNUP_PROMPT = preload("res://scenes/main_menu/pages/landing/login_signup_prompt/LoginSignupPrompt.tscn")


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	if State.user and State.user.initialized:
		logged_in()
		return
	State.user.user_initialized.connect(logged_in)
	State.user.failed.connect(logged_out)


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta: float) -> void:
	pass


func _pressed() -> void:
	if State.user and State.user.initialized:
		logged_in_pressed()
	else:
		logged_out_pressed()


func logged_in_pressed() -> void:
	State._logout()


func logged_out_pressed() -> void:
	var pres := Prompts.new_fullscreen_prompt()
	if pres.is_err():
		return
	var prompt: PromptInstance = pres.val()
	prompt.hide_panel()
	prompt.add_child(LOGIN_SIGNUP_PROMPT.instantiate())


func logged_in() -> void:
	text = "Log out  "
	modulate = Color.WHITE


func logged_out(id: int) -> void:
	text = "Log in  "
	if id == HTTPClient.RESPONSE_IM_A_TEAPOT:
		text = "Log back in  "
		modulate = Color(1, .6, .6)
		
