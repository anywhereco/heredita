class_name RoomPasswordPrompt
extends Control

signal password_submitted(password: String)

@onready var password_edit: LineEdit = $VBoxContainer/PasswordEdit
@onready var attempts_label: Label = $AttemptsLabel


func _ready() -> void:
	password_edit.text_submitted.connect(password_submitted.emit)
	password_edit.grab_focus()


func show_attempts(remaining: int) -> void:
	attempts_label.show()
	attempts_label.text = TranslationServer.translate_plural(
		"network/password.attempt_remaining", "network/password.attempts_remaining", remaining
	)
