extends FunctionalMenuButton

const FLOPPY = preload("res://assets/icons/floppy.svg")
const IMAGE = preload("res://assets/icons/image.svg")
const OPENFOLDER = preload("res://assets/icons/openfolder.svg")


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	if State.player.privileged():
		entry("Save this map", FLOPPY,
			func() -> void:
				var data: MapData = Map._instance.get_data()
				var buffer := data.serialize_with_header()
				FilePrompter.save(self, buffer, "saved_map.map", "map", "application/heredita-map")
		)
		
	entry("Export this map", IMAGE,
		func() -> void:
			var img: Image = Map._instance.get_map_as_image()
			var buffer := img.save_png_to_buffer()
			FilePrompter.save(self, buffer, "saved_map.png", "map_export", "image/png")
	)
	
	if State.player.privileged():
		seperator()
		entry("Load a map", OPENFOLDER, load_map)

	

func load_map() -> void:
	var map_file := await FilePrompter.load_file(self, ImagePickerButton.NO_SVG_MAP_FILTER, ImagePickerButton.NO_SVG_MAP_FILTER_WEB, "map")
	var map := await MapData.create_from_buffer(map_file)
	if map.is_ok():
		State.client.send("load_map")
		@warning_ignore("unsafe_call_argument")
		State.client.chunk_sender.send(ISUtil.BinaryEvents.FORCE_RESYNC_MAP, -1, map.val().serialize())
