extends Button


func _pressed() -> void:
	var data: MapData = Map._instance.get_data()
	var buffer := data.serialize_with_header()
	FilePrompter.save(self, buffer, "saved_map.map", "map", "application/heredita-map")
