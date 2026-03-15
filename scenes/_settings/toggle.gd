extends HBoxContainer

@onready var value: CheckBox = $Value

var setting: ReactiveBool


func _ready() -> void:
	setting.value_changed.connect(_setting_changed)
	_setting_changed(setting)  #initial update


func _on_value_toggled(toggled_on: bool) -> void:
	setting.value = toggled_on


func _setting_changed(new_setting: ReactiveBool) -> void:
	value.button_pressed = new_setting.value
