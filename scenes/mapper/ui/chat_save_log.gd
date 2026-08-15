extends Button

@onready var chat := get_parent().get_parent().get_parent().get_parent()

func _pressed() -> void:
	var chat_log: String = chat.messages_text_full
	var buffer := chat_log.to_utf8_buffer()
	FilePrompter.save(self, buffer, "chat_log.txt", "chat_log")
