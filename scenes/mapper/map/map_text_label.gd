class_name MapTextLabel
extends MeshInstance3D

const FONT: Font = MapTextData.FONT
const FONT_SIZE := MapTextData.FONT_SIZE
const PADDING := MapTextData.PADDING
const CURVE_SEGMENTS := 64
const MATERIAL = preload("res://scenes/mapper/map/map_text.gdshader")
const GEOMETRY = preload("res://scenes/mapper/map/map_text_mesh.gd")

var data: Dictionary
var curve: Curve2D
var half_height := 0.0
var text_start := 0.0
var text_end := 0.0
var _material := ShaderMaterial.new()
var _geometry: MapTextMesh
var _text_bounds: AABB
var _spacing := -1


func _init() -> void:
	cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	_material.shader = MATERIAL
	_material.render_priority = 3
	material_override = _material


func update_label(label: Dictionary, map: Map) -> void:
	var rebuild: bool = data.is_empty() or data.get("text") != label["text"]
	data = label.duplicate(true)
	if rebuild:
		_geometry = GEOMETRY.for_text(String(data["text"]))
	curve = MapTextData.curve_for(data)
	var length := curve.get_baked_length()
	if length < 0.01:
		mesh = null
		return
	var requested_scale := (
		clampf(float(data["size"]), MapTextData.MIN_FONT_SIZE, MapTextData.MAX_FONT_SIZE)
		/ FONT_SIZE
	)
	var natural_width: float = _geometry.bounds.size.x + PADDING * 2.0
	var spacing := 0
	if _geometry.spacing_width > 0.001 and length > natural_width * requested_scale:
		spacing = ceili((length / requested_scale - natural_width) / _geometry.spacing_width)
	if rebuild or spacing != _spacing:
		_spacing = spacing
		_text_bounds = _geometry.bounds_for_spacing(spacing)
		_material.set_shader_parameter("glyph_spacing", float(spacing))
	var text_size := Vector2(_text_bounds.size.x, _text_bounds.size.y) + Vector2.ONE * PADDING * 2.0
	# Round spacing up, then fit uniformly so rounding never pushes the font over its size limit.
	var text_scale := minf(requested_scale, length / text_size.x)
	var width := text_size.x * text_scale
	half_height = text_size.y * text_scale / 2.0
	text_start = (length - width) / 2.0
	text_end = text_start + width
	var points := PackedVector2Array()
	var bounds := Rect2(ISUtil.to_vec2(data["points"][0] as Array), Vector2.ZERO)
	for point: Array in data["points"]:
		points.append(ISUtil.to_vec2(point))
		bounds = bounds.expand(points[-1])
	# Arc length lookup keeps the letters evenly spaced along the cubic Bézier.
	var arc_lengths := PackedFloat32Array([0.0])
	var previous := points[0]
	var total := 0.0
	for idx in range(1, CURVE_SEGMENTS + 1):
		var point := points[0].bezier_interpolate(
			points[1], points[2], points[3], float(idx) / CURVE_SEGMENTS
		)
		total += previous.distance_to(point)
		arc_lengths.append(total)
		previous = point
	for idx in arc_lengths.size():
		arc_lengths[idx] /= maxf(total, 0.001)
	mesh = _geometry.mesh
	_material.set_shader_parameter("curve_points", points)
	_material.set_shader_parameter("arc_lengths", arc_lengths)
	_material.set_shader_parameter("curve_length", length)
	_material.set_shader_parameter("text_start", text_start)
	_material.set_shader_parameter("text_scale", text_scale)
	_material.set_shader_parameter(
		"text_origin", Vector2(_text_bounds.position.x - PADDING, _text_bounds.get_center().y)
	)
	_material.set_shader_parameter("text_color", ISUtil.to_color(data["color"] as Array))
	_material.set_shader_parameter("map_size", map.original_map_size)
	_material.set_shader_parameter("pixel_size", map.pixel_size)
	# Shader displacement must be included in the bounds used for frustum culling.
	bounds = bounds.grow(half_height)
	var origin := map.map_space_to_world_space(bounds.position)
	custom_aabb = AABB(
		Vector3(origin.x, 0.015, origin.y),
		Vector3(bounds.size.x * map.pixel_size, 0.02, bounds.size.y * map.pixel_size)
	)


func hit_distance(pixel: Vector2, margin: float) -> float:
	if curve == null or curve.get_baked_length() < 0.01:
		return INF
	var offset := curve.get_closest_offset(pixel)
	if offset < text_start - margin or offset > text_end + margin:
		return INF
	var distance := pixel.distance_to(curve.sample_baked(offset))
	return distance if distance <= half_height + margin else INF
