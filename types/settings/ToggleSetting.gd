## A setting that can be toggled on and off.
class_name ToggleSetting
extends SettingsResource

## The default value for this toggle.
var default: bool


func _init(_label: String, _default: bool) -> void:
	self.label = _label
	self.default = _default
