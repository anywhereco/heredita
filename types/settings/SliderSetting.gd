## A setting controlled by slider.
class_name SliderSetting
extends SettingsResource

## The type of this slider.
var type: Type
## The default value for this slider.
var default: float
## The minimum value of this slider.
var min_value: float
## The maximum value of this slider.
var max_value: float
## The snap value of this slider.
## If this is -1, there is no snap value.
var snap: float

enum Type {
	FLOAT,
	PERCENT,
	# LOG_FLOAT,
	LOG_PERCENT
}

func _init(_label: String, _type: Type, _default: float, _min: float, _max: float, _snap: float = -1) -> void:
	self.label = _label
	self.type = _type
	self.default = _default
	self.min_value = _min
	self.max_value = _max
	self.snap = _snap

func is_percent() -> bool:
	return type in [Type.PERCENT, Type.LOG_PERCENT]

func is_log() -> bool:
	return type in [Type.LOG_PERCENT]
