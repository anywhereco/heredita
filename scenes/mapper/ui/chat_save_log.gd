extends Button

@onready var chat: VBoxContainer = $"../../../Bottom/ChatSplit/RightItems/ChatPanel/ChatBox"

func _pressed() -> void:
	var chat_log: String = chat.messages_text_full
	var buffer := chat_log.to_utf8_buffer()
	FilePrompter.save(self, buffer, "chat_log.txt", "chat_log")
