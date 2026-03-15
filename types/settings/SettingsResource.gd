## The top level settings resource which all classes are expected to branch from.
class_name SettingsResource
extends Resource

## The user-facing name of this setting.
var label: String


func _init(_label: String) -> void:
	self.label = _label
