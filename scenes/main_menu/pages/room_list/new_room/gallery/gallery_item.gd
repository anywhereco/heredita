extends PanelContainer

@onready var loading_placeholder: Label = $MarginContainer/VBoxContainer/LoadingPlaceholder
@onready var map: TextureRect = $MarginContainer/VBoxContainer/Map
@onready var name_lbl: Label = $MarginContainer/VBoxContainer/HBoxContainer/Name
@onready var attribution_lbl: Label = $MarginContainer/VBoxContainer/HBoxContainer/Attribution

var image: Image
var thumbnail: Image

var map_name: String
var attribution: String
var id: String

var _picker: ImagePickingCoordinator


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	name_lbl.text = map_name
	attribution_lbl.text = tr("roomcreate/gallery.attribution") % attribution

	var http_request := HTTPRequest.new()
	add_child(http_request)
	http_request.request_completed.connect(self._http_request_completed)

	http_request.request("%s/gallery/%s/thumbnail.png" % [Statics.HEREDITA_URL, id])


func prepare_load_full_image() -> void:
	var http_request := HTTPRequest.new()
	add_child(http_request)
	_picker.loading_mutex.lock()
	http_request.request_completed.connect(self._http_request_completed_full)

	http_request.request("%s/gallery/%s/image.png" % [Statics.HEREDITA_URL, id])


func setup(_mappicker: Node, _map_name: String, _attribution: Variant, _id: String) -> void:
	self.map_name = _map_name
	self.attribution = _attribution if _attribution != null else "the Heredita Team"
	self.id = _id
	self._picker = _mappicker


@warning_ignore("unused_parameter")
func _http_request_completed(
	result: int, response_code: int, _headers: PackedStringArray, body: PackedByteArray
) -> void:
	if result != HTTPRequest.RESULT_SUCCESS:
		hide()
		return
	if response_code != 200:
		hide()
		return
	loading_placeholder.hide()
	thumbnail = Image.new()
	if thumbnail.load_png_from_buffer(body) != OK:
		hide()
		return
	thumbnail.convert(Image.FORMAT_RGBA8)
	var tex: ImageTexture = ImageTexture.create_from_image(thumbnail)
	map.texture = tex
	map.show()

	if _picker.current_picked == id:
		_picker.get_parent().get_parent().get_node("MapPickerButton").image.value = thumbnail


func convert_to_map(item: Variant) -> MapData:
	if item is MapData:
		return item
	elif item is Image:
		var _map := MapData.new()
		_map.image = item
		return _map
	else:
		push_error("Invalid map in gallery")
		return MapData.new()


@warning_ignore("unused_parameter")
func _http_request_completed_full(
	result: int, response_code: int, _headers: PackedStringArray, body: PackedByteArray
) -> void:
	if result != HTTPRequest.RESULT_SUCCESS:
		return
	if response_code != 200:
		return
	image = Image.new()
	if image.load_png_from_buffer(body) != OK:
		_picker.loading_mutex.unlock.call_deferred()
		return
	image.convert(Image.FORMAT_RGBA8)
	var map_picker_button: MapPickerButton = _picker.get_parent().get_parent().get_node(
		"MapPickerButton"
	)
	map_picker_button.map._set_value.call_deferred(convert_to_map(image))
	map_picker_button.image.value = image
	_picker.loading_mutex.unlock.call_deferred()
	Prompts.get_prompt_in(self).closing_paused.value = false


func _picked() -> void:
	if _picker.current_picked == id:
		return
	_picker.current_picked = id
	prepare_load_full_image()
	Prompts.get_prompt_in(self).closing_paused.value = true
	var map_picker_button: MapPickerButton = _picker.get_parent().get_parent().get_node(
		"MapPickerButton"
	)
	if thumbnail:
		map_picker_button.image.value = thumbnail
	map_picker_button.get_parent().get_parent().get_parent().get_node("MapName").text = (
		tr("roomcreate/gallery.headerwithattribution")
		. format({"map": map_name, "author": attribution})
	)
