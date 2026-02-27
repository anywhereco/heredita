class_name MapData

var image: Image

const PACKAGE_VERSION = 0

func package() -> Dictionary[String, Variant]:
	return {"image": image.get_data(),
			"image_size": image.get_size()}
	
func serialize() -> PackedByteArray:
	var serialized_map: PackedByteArray = var_to_bytes(package())
	serialized_map.insert(0,PACKAGE_VERSION)
	return serialized_map
	
static func deserialize(serialized: PackedByteArray) -> MapData:
	var md := MapData.new()
	var package_version := serialized[0]
	var s_data := serialized.duplicate()
	s_data.remove_at(0)
	if package_version >= 0:
		var map_data: Dictionary[String, Variant] = bytes_to_var(s_data)
		var image_size: Vector2 = map_data["image_size"]
		@warning_ignore("unsafe_call_argument", "narrowing_conversion")
		md.image = Image.create_from_data(image_size.x,image_size.y,false,Image.FORMAT_RGBA8,map_data["image"])
	return md
	
func get_map_update(details: Dictionary) -> void:
	var type: String = details["type"]
	if type == "brush":
		@warning_ignore("unsafe_call_argument")
		set_pixels_at_targeted(
			State.brush_shape_map.get_vec2s(details["size"]),
			ISUtil.to_color(details["paint_color"]),
			ISUtil.to_color(details["target_color"]),
			ISUtil.to_vec2(details["pos"]))

func is_in_bounding_box(test_point: Vector2, min_corner: Vector2, max_corner: Vector2) -> bool:
	return (test_point.x >= min_corner.x and 
			test_point.x <= max_corner.x and
			test_point.y >= min_corner.y and
			test_point.y <= max_corner.y)

func set_pixels_at_targeted(positions: PackedVector2Array, color: Color, target: Color, offset: Vector2 = Vector2.ZERO) -> void:
	for pos in positions:
		pos += offset
		if not is_in_bounding_box(pos, Vector2.ZERO, image.get_size()-Vector2i(1,1)):
			continue
		if image.get_pixelv(pos).is_equal_approx(target):
			image.set_pixelv(Vector2i(pos), color)
