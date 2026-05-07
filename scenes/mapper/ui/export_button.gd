extends Button


func _pressed() -> void:
	var img: Image = Map._instance.get_map_as_image()
	if OS.has_feature("web"):
		var buffer := img.save_png_to_buffer()
		JavaScriptBridge.download_buffer(buffer, "saved_map.png", "image/png")
	else:
		img.save_png("user://saved_map.png")
