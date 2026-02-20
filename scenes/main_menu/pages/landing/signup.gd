extends VBoxContainer

const error_color = Color(0.91, 0.38, 0.38)

var tween: Tween

var error_label: ErrorLabelForLogin

@onready var username: LineEdit = $Username
@onready var password: LineEdit = $Password
@onready var password_confirmation: LineEdit = $PasswordConfirmation
@onready var email: LineEdit = $Email
@onready var button: Button = $Button

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	error_label = find_parent("LoginSignupPrompt").find_child("ErrorLabel")

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta: float) -> void:
	pass


func _signup_btn() -> void:
	if password.text != password_confirmation.text:
		error_label.err("Password and the confirmation do not match")
		if tween:
			tween.kill()
		password.modulate = error_color
		password_confirmation.modulate = error_color
		button.modulate = error_color
		tween = create_tween().set_ease(Tween.EASE_IN).set_trans(Tween.TRANS_QUINT).set_parallel(true)
		tween.tween_property(password, "modulate", Color.WHITE, 2)
		tween.tween_property(password_confirmation, "modulate", Color.WHITE, 2)
		tween.tween_property(button, "modulate", Color.WHITE, 2)
		return
	if len(password.text) < 8:
		error_label.err("Password must be at least 8 characters long")
		if tween:
			tween.kill()
		password.modulate = error_color
		button.modulate = error_color
		tween = create_tween().set_ease(Tween.EASE_IN).set_trans(Tween.TRANS_QUINT).set_parallel(true)
		tween.tween_property(password, "modulate", Color.WHITE, 2)
		tween.tween_property(button, "modulate", Color.WHITE, 2)
		return
	if len(username.text) < 3:
		error_label.err("Username must be at least 3 characters long")
		if tween:
			tween.kill()
		username.modulate = error_color
		button.modulate = error_color
		tween = create_tween().set_ease(Tween.EASE_IN).set_trans(Tween.TRANS_QUINT).set_parallel(true)
		tween.tween_property(username, "modulate", Color.WHITE, 2)
		tween.tween_property(button, "modulate", Color.WHITE, 2)
		return
	if RegEx.create_from_string("^[a-zA-Z0-9_]+$").search(username.text) == null:
		error_label.err("Username can only contain letters, numbers, and underscores")
		if tween:
			tween.kill()
		username.modulate = error_color
		button.modulate = error_color
		tween = create_tween().set_ease(Tween.EASE_IN).set_trans(Tween.TRANS_QUINT).set_parallel(true)
		tween.tween_property(username, "modulate", Color.WHITE, 2)
		tween.tween_property(button, "modulate", Color.WHITE, 2)
		return
		
	tween = create_tween().set_ease(Tween.EASE_IN_OUT).set_trans(Tween.TRANS_SINE)
	for i in 10:
		tween.tween_property(button, "modulate", Color(.8, .8, .8), .5)
		tween.tween_property(button, "modulate", Color.WHITE, .5)
	tween.tween_callback(func() -> void: error_label.err("Server took too long to respond"))
	tween.set_parallel(true)
	tween.tween_callback(func() -> void: button.modulate = error_color)
	tween.tween_property(button, "modulate", Color.WHITE, 2)
	
	State.user.failed.connect(func(response_code: int) -> void:
		tween.kill()
		if response_code == 403:
			button.modulate = error_color
			error_label.err("That username is already in use")
			tween = create_tween().set_ease(Tween.EASE_IN).set_trans(Tween.TRANS_QUINT)
			tween.tween_property(button, "modulate", Color.WHITE, 2)
		else:
			button.modulate = error_color
			error_label.err("Server error (try again later)")
			tween = create_tween().set_ease(Tween.EASE_IN).set_trans(Tween.TRANS_QUINT)
			tween.tween_property(button, "modulate", Color.WHITE, 2)
	)
	State.user.user_initialized.connect(close)
	
	State.user.signup(username.text, password.text, email.text)
	
func close() -> void:
	State.user.user_initialized.disconnect(close)
	find_parent("LoginSignupPrompt").get_parent().close()
