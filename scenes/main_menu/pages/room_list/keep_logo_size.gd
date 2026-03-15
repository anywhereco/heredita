extends TextureRect

const MIN = 96.0
const MAX = 144.0


func _ready() -> void:
	State.display.scale.value_changed.connect(rescaler)


func rescaler(val: ReactiveFloat) -> void:
	var _size := clampf(remap(val.value, 1, MAX / MIN, MIN, MAX), MIN, MAX)
	custom_minimum_size = Vector2(_size, _size)
