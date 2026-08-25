class_name FilePrompter

static var default_locations: Dictionary[String, String] = {} #TODO: make this save between sessions

## Open a save dialog.
## Root is the parent of the dialog (on desktop).
## Type is a category used to save default directories between dialogs.
static func save(root: Node, buffer: PackedByteArray, default_filename: String, type: String = "", mime: String = "text/plain") -> void:
	if OS.has_feature("web"):
		JavaScriptBridge.download_buffer(buffer, default_filename, mime)
	else:
		var file_dialog := FileDialog.new()
		file_dialog.use_native_dialog = true
		file_dialog.file_mode = FileDialog.FILE_MODE_SAVE_FILE
		file_dialog.access = FileDialog.ACCESS_FILESYSTEM
		if type in default_locations:
			print(default_locations[type])
			file_dialog.current_dir = default_locations[type]
			print(file_dialog.current_dir)
		file_dialog.file_selected.connect(_on_save_file_selected.bind(buffer, type))
		root.add_child(file_dialog, false, root.INTERNAL_MODE_BACK)
		file_dialog.popup_centered(file_dialog.min_size)
		
static func _on_save_file_selected(path: String, buffer: PackedByteArray, type: String) -> void:
	default_locations[type] = path.get_base_dir()
	var file := FileAccess.open(path, FileAccess.WRITE)
	file.store_buffer(buffer)

static func load_file(root: Node, filter: PackedStringArray, filter_web: PackedStringArray, type: String = "") -> PackedByteArray:
	if OS.has_feature("web"):
		var web_file_dialog := HTML5FileDialog.new()
		web_file_dialog.file_mode = HTML5FileDialog.FileMode.OPEN_FILE
		web_file_dialog.filters = filter_web
		root.add_child(web_file_dialog, false, root.INTERNAL_MODE_BACK)
		web_file_dialog.register()
		web_file_dialog.show()
		var handle: HTML5FileHandle = await web_file_dialog.file_selected
		return await handle.as_buffer()
	else:
		var file_dialog := FileDialog.new()
		file_dialog.use_native_dialog = true
		file_dialog.file_mode = FileDialog.FILE_MODE_OPEN_FILE
		file_dialog.access = FileDialog.ACCESS_FILESYSTEM
		file_dialog.filters = filter
		if type in default_locations:
			print(default_locations[type])
			file_dialog.current_dir = default_locations[type]
			print(file_dialog.current_dir)
		root.add_child(file_dialog, false, root.INTERNAL_MODE_BACK)
		file_dialog.popup_centered(file_dialog.min_size)
		var path: String = await file_dialog.file_selected
		return FileAccess.get_file_as_bytes(path)
