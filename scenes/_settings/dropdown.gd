extends HBoxContainer

@onready var value: OptionButton = $Value

var setting: ReactiveInt


func _ready() -> void:
	setting.value_changed.connect(_setting_changed)
	_setting_changed(setting)  #initial update


func _on_item_selected(index: int) -> void:
	setting.value = index


func _setting_changed(new_setting: ReactiveInt) -> void:
	value.selected = new_setting.value
