extends HBoxContainer

@onready var count: Label = $Count
@onready var ppu_slider: HSlider = $PPUSlider
@onready var text := tr("roomcreate/pixelsperunit.value") 

const FACTOR := 32.0

var value := 32.0

func _ready() -> void:
	_on_ppu_slider_value_changed(ppu_slider.value)


func _on_ppu_slider_value_changed(slider_value: float) -> void:
	var reciprocal_value := FACTOR / slider_value
	count.text = text % reciprocal_value
	value = 1 / reciprocal_value
