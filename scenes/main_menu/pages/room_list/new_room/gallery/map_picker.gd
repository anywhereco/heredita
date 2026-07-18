extends HBoxContainer

const MAP_BLANK = preload("uid://do2qcumlvx0lo")

@onready var map_picker_button: MapPickerButton = $MapPickerButton
@onready var map_name: Label = $"../../MapName"

var image: ReactiveImage
var map: ReactiveMapData

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	image = map_picker_button.image
	map = map_picker_button.map
	image.value = MAP_BLANK.duplicate()
	map_name.text = tr("roomcreate/gallery.header") % "Default"
