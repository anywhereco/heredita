class_name MapData

var image: Image
var map_last_painter := PackedInt32Array()
var map_last_color := PackedColorArray()
var map_width := -1
var markings: Array[Dictionary] = []

const PACKAGE_VERSION = 1

const _MAGIC_FILE_HEADER = 0x01_02_03_4D_50_4D_61_70 # 1, 2, 3, MPMap!

enum FileReadErrors {
	NOT_HEREDITA_MAP
}

func package() -> Dictionary[String, Variant]:
	return {"image": image.get_data(), "image_size": image.get_size(), "markings": markings}


func serialize() -> PackedByteArray:
	var serialized_map: PackedByteArray = var_to_bytes(package())
	serialized_map.insert(0, PACKAGE_VERSION)
	return serialized_map

## Used for writing to files
func serialize_with_header() -> PackedByteArray:
	var data := serialize()
	var uncompressed_size := len(data)
	var compressed_data := data.compress(FileAccess.COMPRESSION_ZSTD)
	var content := PackedByteArray()
	content.resize(16)
	content.encode_u64(0, _MAGIC_FILE_HEADER) 
	content.encode_u64(8, uncompressed_size)
	content.append_array(compressed_data)
	return content

static func read_from_file(path: String) -> Result:
	var file := FileAccess.open(path, FileAccess.READ)
	var data := file.get_buffer(file.get_length())
	if data.decode_u64(0) != _MAGIC_FILE_HEADER:
		return Result.err(FileReadErrors.NOT_HEREDITA_MAP)
	var decompressed := data.slice(16).decompress(data.decode_u64(8), FileAccess.COMPRESSION_ZSTD)
	return Result.ok(deserialize(decompressed))

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
		if map_data.has("markings") and map_data["markings"] is Array:
			for marking: Variant in map_data["markings"]:
				@warning_ignore("unsafe_call_argument")
				if marking is Dictionary and _valid_serialized_marking(marking):
					md.markings.append(marking)
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
	elif type == "marking":
		apply_marking_update(details)


static func _valid_marking_type(marking_type: Variant) -> bool:
	return marking_type is String and marking_type in ["city", "fort"]


static func _valid_marking_id(id: Variant) -> bool:
	return id is String and not id.is_empty() and id.length() <= 128


static func _valid_marking_name(name: Variant) -> bool:
	return name is String and name.length() <= 64


static func _valid_number(number: Variant) -> bool:
	@warning_ignore("unsafe_call_argument")
	return Verify.is_numeric(number) and absf(float(number)) < INF


static func _valid_color_array(color: Variant) -> bool:
	return (
		color is Array
		and color.size() >= 3
		and _valid_number(color[0])
		and _valid_number(color[1])
		and _valid_number(color[2])
	)


static func _valid_vec2_array(vec: Variant) -> bool:
	return vec is Array and vec.size() >= 2 and _valid_number(vec[0]) and _valid_number(vec[1])


static func _valid_serialized_marking(marking: Dictionary) -> bool:
	return (
		_valid_marking_id(marking.get("id"))
		and _valid_marking_type(marking.get("marking_type"))
		and _valid_vec2_array(marking.get("position"))
		and _valid_number(marking.get("scale"))
		and _valid_number(marking.get("rotation"))
		and _valid_color_array(marking.get("color"))
		and _valid_marking_name(marking.get("name", ""))
	)


func _marking_index(id: String) -> int:
	for idx in markings.size():
		if markings[idx].get("id") == id:
			return idx
	return -1


func apply_marking_update(details: Dictionary) -> void:
	var op: Variant = details.get("op")
	var id: Variant = details.get("id")
	if not _valid_marking_id(id):
		return

	if op == "create":
		if not _valid_serialized_marking(details):
			return
		@warning_ignore("unsafe_call_argument")
		var marking := {
			"id": details["id"],
			"marking_type": details["marking_type"],
			"position": details["position"],
			"scale": clampf(float(details["scale"]), 0.1, 5.0),
			"rotation": float(details["rotation"]),
			"color": details["color"],
			"name": details.get("name", "")
		}
		@warning_ignore("unsafe_call_argument")
		var existing_idx := _marking_index(id)
		if existing_idx == -1:
			markings.append(marking)
		else:
			markings[existing_idx] = marking
	elif op == "delete":
		@warning_ignore("unsafe_call_argument")
		var idx := _marking_index(id)
		if idx != -1:
			markings.remove_at(idx)
	elif op == "edit":
		@warning_ignore("unsafe_call_argument")
		var idx := _marking_index(id)
		if idx == -1:
			return
		var marking := markings[idx].duplicate()
		if details.has("color"):
			if not _valid_color_array(details["color"]):
				return
			marking["color"] = details["color"]
		if details.has("name"):
			if not _valid_marking_name(details["name"]):
				return
			marking["name"] = details["name"]
		markings[idx] = marking


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
