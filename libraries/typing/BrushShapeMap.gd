class_name BrushShapeMap
extends Resource

const DEFAULT = preload("uid://bug42uo2av8i2")

const BRUSH_SIZE_MAX = BrushShapes.SIZE_MAX

var image_pixel_offset := Vector2(
	floorf(DEFAULT.get_size().x / 2.0), floorf(DEFAULT.get_size().x / 2.0)
)

var circle_image_map: Dictionary[int, Image]


func _init() -> void:
	_bake_shape_map()


func _bake_shape_map() -> void:
	for size: int in range(1, BRUSH_SIZE_MAX + 1):
		circle_image_map.set(size, _make_image(size))


func _make_image(size: int) -> Image:
	@warning_ignore("unsafe_call_argument")
	var image := Image.create_from_data(
		DEFAULT.get_size().x, DEFAULT.get_size().y, false, DEFAULT.get_format(), DEFAULT.get_data()
	)
	for vec: Vector2 in BrushShapes.circle(size):
		vec += image_pixel_offset
		image.set_pixelv(vec, Color.WHITE)
	return image


func get_vec2s(size: int) -> PackedVector2Array:
	return BrushShapes.circle(size)


func get_as_image(size: int) -> Image:
	return circle_image_map.get(size)
