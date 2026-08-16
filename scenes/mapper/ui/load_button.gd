extends Button


func _pressed() -> void:
	var map_file := await FilePrompter.load_file(self, ImagePickerButton.NO_SVG_MAP_FILTER, ImagePickerButton.NO_SVG_MAP_FILTER_WEB, "map")
	var map := await MapData.create_from_buffer(map_file)
	if map.is_ok():
		State.client.send("load_map")
		State.client.chunk_sender.send(ISUtil.BinaryEvents.FORCE_RESYNC_MAP, -1, map.val().serialize())
