extends ImagePickerButton
class_name MapPickerButton

var map := ReactiveMapData.new(null)

func _on_file_selected_html5(file: HTML5FileHandle) -> void:
	var res := await _file_handle_to_map(file)
	if res.is_err():
		_err(res.err_code() as int)
		return
	map.value = res.val()
	image.value = res.val().image
	_new_image(file.name)
	
func _on_file_selected(path: String) -> void:
	var fmt := path.rsplit(".", false, 1)[1]
	var _map: MapData
	if fmt == "map":
		var result := MapData.read_from_file(path)
		if result.is_ok():
			_map = result.val()
	else:
		var img: Image = Image.load_from_file(path)
		if img == null:
			_err(PickedImageError.NOT_VALID_FILE_FORMAT)
			return
		img.convert(Image.FORMAT_RGBA8)
		_map = MapData.new()
		_map.image = img
	map.value = _map
	_new_image(path.get_file())
	
func _file_handle_to_map(file: HTML5FileHandle) -> Result:
	var fmt := file.name.rsplit(".", false, 1)[1]
	var buf := await file.as_buffer()
	var _map: MapData
	if fmt == "map":
		var result := MapData.read_from_buffer(buf)
		if result.is_ok():
			_map = result.val()
	else:
		var get_image := await _file_handle_to_image(file)
		if get_image.is_ok():
			_map = MapData.new()
			_map.image = get_image.val()
		else:
			return get_image
	return Result.ok(_map)

func _ready() -> void:
	allow_maps = true
	allow_svgs = false
	super()
