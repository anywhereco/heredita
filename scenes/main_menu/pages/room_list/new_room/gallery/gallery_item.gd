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
	thumbnail = Image.create_empty(256, 128, false, Image.FORMAT_RGBA8)
	thumbnail.load_png_from_buffer(body)
	var tex: ImageTexture = ImageTexture.create_from_image(thumbnail)
	map.texture = tex
	map.show()

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
	image = Image.create_empty(4096, 2048, false, Image.FORMAT_RGBA8)
	image.load_png_from_buffer(body)  # TODO: support .map soonish [when its actually a thing]      haha i updated your todo -Digi
	(
		_picker
		. get_parent()
		. get_parent()
		. get_parent()
		. find_child("MapPickerButton")
		. map
		. _set_value
		. call_deferred(convert_to_map(image))
	)
	_picker.loading_mutex.unlock.call_deferred()  # TODO: probably need to be smarter about running this
	Prompts.get_prompt_in(self).closing_paused.value = false


func _picked() -> void:
	if _picker.current_picked == id:
		return
	_picker.current_picked = id
	prepare_load_full_image()
	Prompts.get_prompt_in(self).closing_paused.value = true
	_picker.get_parent().get_parent().get_parent().find_child("MapPickerButton").image.value = thumbnail
	_picker.get_parent().get_parent().get_parent().get_parent().find_child("MapName").text = (
		tr("roomcreate/gallery.headerwithattribution").format(
			{"map": map_name, "author": attribution}
		)
	)
