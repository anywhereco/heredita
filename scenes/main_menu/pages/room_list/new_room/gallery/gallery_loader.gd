class_name ImagePickingCoordinator
extends MarginContainer

const GALLERY_ITEM = preload("uid://bj8dbj28fas7r")
@onready var placeholder: Label = $LoadingPlaceholder
@onready var elements: HBoxContainer = $Gallery/Elements

var loading_mutex := Mutex.new()
var current_picked := "blank"


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	var http_request := HTTPRequest.new()
	add_child(http_request)
	http_request.request_completed.connect(self._initial_request_completed)
	http_request.request("%s/gallery/" % Statics.HEREDITA_URL)


func _initial_request_completed(
	result: int, response_code: int, _headers: PackedStringArray, body: PackedByteArray
) -> void:
	if result != HTTPRequest.RESULT_SUCCESS:
		placeholder.text = tr("roomcreate/gallery.fail")
		return
	if response_code != 200:
		placeholder.text = tr("roomcreate/gallery.fail")
		return
	var json: Variant = JSON.parse_string(body.get_string_from_utf8())
	if json == null:
		placeholder.text = tr("roomcreate/gallery.fail")
		return
	placeholder.hide()
	var items: Array = json
	for item_data: Dictionary in items:
		var item := GALLERY_ITEM.instantiate()
		print(item_data)
		item.setup(self, item_data.name, item_data.attribution, item_data.id)
		elements.add_child(item)
