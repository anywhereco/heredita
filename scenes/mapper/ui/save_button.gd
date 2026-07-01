extends Button


func _pressed() -> void:
	var data: MapData = Map._instance.get_data()
	if OS.has_feature("web"):
		var buffer := data.serialize_with_header()
		JavaScriptBridge.download_buffer(buffer, "saved_map.map", "application/heredita-map")
	else:
		var file := FileAccess.open("user://saved_map.map", FileAccess.WRITE)
		file.store_buffer(data.serialize_with_header())
