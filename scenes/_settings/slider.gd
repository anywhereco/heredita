extends HBoxContainer

var setting: ReactiveFloat

var percent := false
var log10 := false

@onready var slider: HSlider = $Slider


func _ready() -> void:
	setting.value_changed.connect(_setting_changed)
	_setting_changed(setting)  #initial update
	_set_label(setting.value)


func _get_value() -> float:
	if log10:
		return Math.exp10(slider.value)
	else:
		return slider.value


func _set_label(value: float) -> void:
	if percent:
		$Value.text = "%d%%" % (value * 100)
	else:
		$Value.text = "%.2f" % value


func _slider_changed(_value: float) -> void:
	_set_label(_get_value())


func _slider_let_go(_value_changed: bool) -> void:
	setting.value = _get_value()


func _setting_changed(_setting: ReactiveFloat) -> void:
	if log10:
		$Slider.value = Math.log10(setting.value)
	else:
		$Slider.value = setting.value
