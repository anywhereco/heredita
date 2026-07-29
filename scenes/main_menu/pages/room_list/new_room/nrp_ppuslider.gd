extends VBoxContainer

const FACTOR := 50

var reactive_map: ReactiveMapData
var _updating := false

@onready var count: Label = $CountContainer/Count
@onready var ppu_slider: HSlider = $PPUSlider
@onready var text := tr("roomcreate/pixelsize.value")


func _ready() -> void:
	if not ppu_slider.value_changed.is_connected(_on_ppu_slider_value_changed):
		ppu_slider.value_changed.connect(_on_ppu_slider_value_changed)


func setup(map: ReactiveMapData) -> void:
	reactive_map = map
	if not reactive_map.value_changed.is_connected(_on_map_changed):
		reactive_map.value_changed.connect(_on_map_changed)
	_update_from_map()


func _on_map_changed(_new_map: MapData) -> void:
	_update_from_map()


func _update_from_map() -> void:
	if reactive_map == null:
		return
	_updating = true
	ppu_slider.value = reactive_map.value.pixel_size * FACTOR
	_update_display(reactive_map.value.pixel_size)
	_updating = false


func _on_ppu_slider_value_changed(slider_value: float) -> void:
	if _updating:
		return
	var new_pixel_size := slider_value / FACTOR
	if reactive_map != null:
		reactive_map.value.pixel_size = new_pixel_size
	_update_display(new_pixel_size)


func _update_display(pixel_size_value: float) -> void:
	count.text = text % pixel_size_value
