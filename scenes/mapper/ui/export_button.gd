extends Button


func _pressed() -> void:
	var img: Image = Map._instance.get_map_as_image()
	var buffer := img.save_png_to_buffer()
	FilePrompter.save(self, buffer, "saved_map.png", "map_export", "image/png")
