extends TextEdit
class_name ChatTextBox

signal text_submitted(new_text: String)

func _input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.is_pressed() and event.button_index == 1:
		var evLocal := make_input_local(event)
		if !Rect2(Vector2(0, 0), size).has_point(evLocal.position as Vector2):
			release_focus()
	if event is InputEventKey and has_focus():
		if event.pressed and event.keycode in [KEY_ENTER, KEY_KP_ENTER]:
			if not event.shift_pressed:
				accept_event()
				submit()

func submit() -> void:
	var submitting_text := text.strip_edges()
	text_submitted.emit(submitting_text)
	text = ""
