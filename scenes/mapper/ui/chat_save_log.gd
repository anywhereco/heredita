extends Button

@onready var chat := get_parent().get_parent().get_parent().get_parent()

func _pressed() -> void:
	var log: String = chat.messages_text_full
	var buffer := log.to_utf8_buffer()
	if OS.has_feature("web"):
		JavaScriptBridge.download_buffer(buffer, "chat_log.txt", "text/plain")
	else:
		var file := FileAccess.open("user://chat_log.txt", FileAccess.WRITE)
		file.store_buffer(buffer)
