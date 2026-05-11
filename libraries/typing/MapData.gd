class_name MapData

var image: Image
var map_last_painter := PackedInt32Array()
var map_last_color := PackedColorArray()
var map_width := -1

const PACKAGE_VERSION = 0


func package() -> Dictionary[String, Variant]:
	return {"image": image.get_data(), "image_size": image.get_size()}


func serialize() -> PackedByteArray:
	var serialized_map: PackedByteArray = var_to_bytes(package())
	serialized_map.insert(0, PACKAGE_VERSION)
	return serialized_map


static func deserialize(serialized: PackedByteArray, is_server: bool = false) -> MapData:
	var md := MapData.new()
	var package_version := serialized[0]
	var s_data := serialized.duplicate()
	s_data.remove_at(0)
	if package_version >= 0:
		var map_data: Dictionary[String, Variant] = bytes_to_var(s_data)
		var image_size: Vector2i = map_data["image_size"]
		@warning_ignore("unsafe_call_argument")
		md.image = Image.create_from_data(
			image_size.x, image_size.y, false, Image.FORMAT_RGBA8, map_data["image"]
		)
		md.map_width = image_size.x
		if is_server:
			md.map_last_painter.resize(image_size.x * image_size.y)
			md.map_last_painter.fill(-2)
			md.map_last_color.resize(image_size.x * image_size.y)
			md.map_last_color.fill(Color.TRANSPARENT)
	return md


func get_map_update(details: Dictionary, peer: int) -> void:
	var type: String = details["type"]
	if type == "brush":
		if (
			typeof(details["size"]) != TYPE_FLOAT
			or typeof(details["targeted"]) != TYPE_BOOL
			or not Verify.array_is_type(details["paint_color"], TYPE_FLOAT)
			or not Verify.array_is_type(details["target_color"], TYPE_FLOAT)
			or not Verify.array_is_type(details["pos"], TYPE_FLOAT)
		):
			return
		@warning_ignore("unsafe_call_argument")
		set_pixels_at_maybe_targeted(
			State.brush_shape_map.get_vec2s(details["size"]),
			ISUtil.to_color(details["paint_color"]),
			ISUtil.to_color(details["target_color"]),
			details["targeted"],
			ISUtil.to_vec2(details["pos"]),
			peer
		)


func is_in_bounding_box(test_point: Vector2, min_corner: Vector2, max_corner: Vector2) -> bool:
	return (
		test_point.x >= min_corner.x
		and test_point.x <= max_corner.x
		and test_point.y >= min_corner.y
		and test_point.y <= max_corner.y
	)


func set_pixels_at_targeted(
	positions: PackedVector2Array, color: Color, target: Color, offset: Vector2, peer: int
) -> void:
	for pos in positions:
		pos += offset
		if not is_in_bounding_box(pos, Vector2.ZERO, image.get_size() - Vector2i(1, 1)):
			continue
		var img_color := image.get_pixelv(pos)
		if img_color.is_equal_approx(target):
			map_last_color[int(pos.y * map_width + pos.x)] = img_color
			map_last_painter[int(pos.y * map_width + pos.x)] = peer
			image.set_pixelv(Vector2i(pos), color)

func set_pixels_at(
	positions: PackedVector2Array, color: Color, offset: Vector2, peer: int
) -> void:
	for pos in positions:
		pos += offset
		if not is_in_bounding_box(pos, Vector2.ZERO, image.get_size() - Vector2i(1, 1)):
			continue
		var img_color := image.get_pixelv(pos)
		if img_color.a > 0:
			map_last_color[int(pos.y * map_width + pos.x)] = img_color
			map_last_painter[int(pos.y * map_width + pos.x)] = peer
			image.set_pixelv(Vector2i(pos), color)

func set_pixels_at_maybe_targeted(
	positions: PackedVector2Array, color: Color, target: Color, targeted: bool, offset: Vector2, peer: int
) -> void:
	offset = offset.floor()
	if targeted:
		set_pixels_at_targeted(positions, color, target, offset, peer)
	else:
		set_pixels_at(positions, color, offset, peer)
