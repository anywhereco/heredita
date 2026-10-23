class_name MapTextData
extends RefCounted

const MAX_LABELS := 512
const MAX_TEXT_LENGTH := 256
# Sizes and curve lengths use map pixels, independently of the map's world scale.
const MIN_FONT_SIZE := 1.0
const MAX_FONT_SIZE := 16.0
const DEFAULT_FONT_SIZE := 4.0
const MIN_CURVE_LENGTH := 10.0
const FONT: Font = preload("res://assets/font/_variants/pro650.tres")
const FONT_SIZE := 48
const PADDING := 4.5

var labels: Dictionary[String, Dictionary] = {}
static var _measurement_font: FontVariation


func serialize() -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	for label: Dictionary in labels.values():
		result.append(label.duplicate(true))
	return result


func load_labels(values: Array, bounds: Vector2) -> void:
	labels.clear()
	for value: Variant in values:
		if value is Dictionary:
			var update: Dictionary = value.duplicate(true)
			update["op"] = "create"
			apply_update(update, bounds)


func apply_update(details: Dictionary, bounds: Vector2) -> bool:
	var id: Variant = details.get("id")
	if not id is String or id.is_empty() or id.length() > 128:
		return false
	var op: Variant = details.get("op")
	if not op is String:
		return false
	if op == "delete":
		return labels.erase(id)
	if op != "create" and op != "edit":
		return false
	if op == "edit" and not labels.has(id):
		return false
	if not labels.has(id) and labels.size() >= MAX_LABELS:
		return false
	var label: Dictionary = labels[id].duplicate(true) if op == "edit" else {"id": id}
	for key: String in ["text", "size", "color", "points"]:
		if details.has(key):
			label[key] = details[key]
	if not _valid_label(label):
		return false
	label["text"] = String(label["text"]).replace("\n", " ").replace("\r", " ")
	label["size"] = clampf(float(label["size"]), MIN_FONT_SIZE, MAX_FONT_SIZE)
	var points: Array = []
	for point: Array in label["points"]:
		points.append(
			[clampf(float(point[0]), 0.0, bounds.x), clampf(float(point[1]), 0.0, bounds.y)]
		)
	label["points"] = points
	var color: Array = label["color"]
	label["color"] = [
		clampf(float(color[0]), 0.0, 1.0),
		clampf(float(color[1]), 0.0, 1.0),
		clampf(float(color[2]), 0.0, 1.0)
	]
	ensure_minimum_length(label, bounds)
	labels[id] = label
	return true


static func text_width(text: String, size: float) -> float:
	if _measurement_font == null:
		_measurement_font = font_for_spacing(0)
	var width := _measurement_font.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, FONT_SIZE).x
	return (width + PADDING * 2.0) * size / FONT_SIZE


static func font_for_spacing(spacing: int) -> FontVariation:
	var font := FONT.duplicate() as FontVariation
	var features := font.opentype_features.duplicate()
	var text_server := TextServerManager.get_primary_interface()
	# Optional ligatures must not combine characters that need separate spacing.
	features[text_server.name_to_tag("liga")] = 0
	features[text_server.name_to_tag("clig")] = 0
	font.opentype_features = features
	font.spacing_glyph = spacing
	return font


static func ensure_minimum_length(label: Dictionary, bounds: Vector2) -> void:
	var font_size := clampf(float(label["size"]), MIN_FONT_SIZE, MAX_FONT_SIZE)
	var minimum := maxf(MIN_CURVE_LENGTH, text_width(String(label["text"]), font_size))
	# Very small maps can only accommodate a span up to their diagonal.
	minimum = minf(minimum, bounds.length() * 0.95)
	var length := curve_for(label).get_baked_length()
	if length >= minimum - 0.0001:
		return
	var points := PackedVector2Array()
	var rect := Rect2(ISUtil.to_vec2(label["points"][0] as Array), Vector2.ZERO)
	for point: Array in label["points"]:
		points.append(ISUtil.to_vec2(point))
		rect = rect.expand(points[-1])
	if length > 0.001:
		var factor := minimum / length * 1.01
		var half_size := rect.size * factor / 2.0
		if half_size.x * 2.0 <= bounds.x and half_size.y * 2.0 <= bounds.y:
			var center := rect.get_center().clamp(half_size, bounds - half_size)
			for idx in 4:
				label["points"][idx] = ISUtil.from_vec2(
					(points[idx] - rect.get_center()) * factor + center
				)
			return
	# A collapsed curve or one that cannot be enlarged in place gets a usable straight span.
	var direction := points[3] - points[0]
	direction = direction.normalized() if not direction.is_zero_approx() else Vector2.RIGHT
	var span := direction * minimum
	if absf(span.x) > bounds.x or absf(span.y) > bounds.y:
		span = bounds.normalized() * minimum
	var start := (rect.get_center() - span / 2.0).clamp(
		-span.min(Vector2.ZERO), bounds - span.max(Vector2.ZERO)
	)
	for idx in 4:
		label["points"][idx] = ISUtil.from_vec2(start + span * (float(idx) / 3.0))


static func _valid_number(value: Variant) -> bool:
	return (value is int or value is float) and is_finite(float(value))


static func _valid_label(label: Dictionary) -> bool:
	var content: Variant = label.get("text")
	if (
		not content is String
		or content.length() > MAX_TEXT_LENGTH
		or content.strip_edges().is_empty()
	):
		return false
	if not _valid_number(label.get("size")):
		return false
	var color: Variant = label.get("color")
	if not color is Array or color.size() != 3:
		return false
	for component: Variant in color:
		if not _valid_number(component):
			return false
	var points: Variant = label.get("points")
	if not points is Array or points.size() != 4:
		return false
	for point: Variant in points:
		if not point is Array or point.size() != 2:
			return false
		if not _valid_number(point[0]) or not _valid_number(point[1]):
			return false
	return true


static func curve_for(label: Dictionary) -> Curve2D:
	var points: Array = label["points"]
	var start := ISUtil.to_vec2(points[0] as Array)
	var end := ISUtil.to_vec2(points[3] as Array)
	var curve := Curve2D.new()
	# Bound the baking cost even for very large maps.
	var control_length := 0.0
	for idx in 3:
		control_length += ISUtil.to_vec2(points[idx] as Array).distance_to(
			ISUtil.to_vec2(points[idx + 1] as Array)
		)
	curve.bake_interval = maxf(0.5, control_length / 512.0)
	curve.add_point(start, Vector2.ZERO, ISUtil.to_vec2(points[1] as Array) - start)
	curve.add_point(end, ISUtil.to_vec2(points[2] as Array) - end, Vector2.ZERO)
	return curve
