extends Node
class_name ReactiveHelper


static func convert(value: Variant) -> Reactive:
	if value is Array:
		return ReactiveArray.new(value as Array)
	elif value is bool:
		return ReactiveBool.new(value as bool)
	elif value is Dictionary:
		return ReactiveDictionary.new(value as Dictionary)
	elif value is float:
		return ReactiveFloat.new(value as float)
	elif value is int:
		return ReactiveInt.new(value as int)
	elif value is String:
		return ReactiveString.new(value as String)
	elif value is Color:
		return ReactiveColor.new(value as Color)
	elif value is Image:
		return ReactiveImage.new(value as Image)
	elif value is Vector2:
		return ReactiveVector2.new(value as Vector2)
	else:
		return null
