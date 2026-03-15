extends LineEdit


func random_username() -> String:
	return "User%d" % randi_range(0, 999)


func _ready() -> void:
	if State.user.initialized:
		hide()
	else:
		text = random_username()
		State.guest_username = text


func _on_text_changed(new_text: String) -> void:
	State.guest_username = new_text
	pass
