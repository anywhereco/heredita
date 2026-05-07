## A setting controlled by slider.
class_name SliderSetting
extends SettingsResource

## The type of this slider.
@export var type: Type
## The default value for this slider.
@export var default: float
## The minimum value of this slider.
@export var min_value: float
## The maximum value of this slider.
@export var max_value: float
## The snap value of this slider.
## If this is -1, there is no snap value.
@export var snap: float = -1

enum Type {
	FLOAT,
	PERCENT,
	# LOG_FLOAT,
	LOG_PERCENT
}


func is_percent() -> bool:
	return type in [Type.PERCENT, Type.LOG_PERCENT]


func is_log() -> bool:
	return type in [Type.LOG_PERCENT]
