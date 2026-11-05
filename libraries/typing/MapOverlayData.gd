class_name MapOverlayData
extends RefCounted

const MAX_OVERLAYS := 32
const MAX_IMAGE_BYTES := 16 * 1024 * 1024
const MAX_TOTAL_BYTES := 64 * 1024 * 1024
const MAX_IMAGE_PIXELS := 16 * 1024 * 1024
const MAX_IMAGE_SIDE := 8192
const DEFAULT_OPACITY := 0.25
const DEFAULT_FILTER := "linear"
const FILTER_MODES := ["nearest", "linear"]

# Images are embedded PNGs and always cover the entire map.
var overlays: Dictionary[String, Dictionary] = {}


func serialize() -> Array[Dictionary]:
	return overlays.values().duplicate(true)


func load_overlays(values: Array) -> void:
	overlays.clear()
	for value: Variant in values:
		if value is Dictionary:
			apply_update(value.merged({"op": "create"}, true))


func apply_update(details: Dictionary) -> bool:
	var id: Variant = details.get("id")
	if not id is String or id.is_empty() or id.length() > 128:
		return false
	var op: Variant = details.get("op")
	if op == "delete":
		return overlays.erase(id)
	if op not in ["create", "edit"]:
		return false
	if op == "edit" and not overlays.has(id):
		return false
	if op == "create" and (overlays.has(id) or overlays.size() >= MAX_OVERLAYS):
		return false
	var overlay: Dictionary = overlays[id].duplicate() if op == "edit" else {"id": id, "filter": DEFAULT_FILTER}
	for key: String in ["name", "opacity", "filter"]:
		if details.has(key):
			overlay[key] = details[key]
	if (
		not overlay.get("name") is String
		or overlay["name"].length() > 128
		or not _valid_number(overlay.get("opacity"))
		or overlay.get("filter") not in FILTER_MODES
	):
		return false
	if op == "create":
		var png: Variant = details.get("image")
		if not png is PackedByteArray or image_from_buffer(png) == null:
			return false
		var total: int = png.size()
		for existing: Dictionary in overlays.values():
			total += (existing["image"] as PackedByteArray).size()
		if total > MAX_TOTAL_BYTES:
			return false
		overlay["image"] = png
	overlay["opacity"] = clampf(float(overlay["opacity"]), 0.0, 1.0)
	overlays[id] = overlay
	return true


func canonical_update(details: Dictionary) -> Dictionary:
	var id: String = details["id"]
	var result := {"type": "overlay", "op": details["op"], "id": id}
	if details["op"] != "delete":
		result.merge(overlays[id].duplicate(true))
		if details["op"] == "edit":
			result.erase("image")
	return result


static func image_from_buffer(buffer: PackedByteArray, format: String = "png") -> Image:
	if buffer.size() > MAX_IMAGE_BYTES or format not in ["png", "jpg", "jpeg", "webp", "bmp"]:
		return null
	var stream := StreamPeerBuffer.new()
	stream.data_array = buffer
	var size := ImageHeaderReader.get_reader(format).read_resolution(stream)
	if (
		size.x <= 0 or size.y <= 0 or size.x > MAX_IMAGE_SIDE or size.y > MAX_IMAGE_SIDE
		or size.x * size.y > MAX_IMAGE_PIXELS
	):
		return null
	var result := MapData._bytes_to_image(format, buffer)
	return result.val() if result.is_ok() else null


static func _valid_number(value: Variant) -> bool:
	return (value is float or value is int) and is_finite(float(value))
