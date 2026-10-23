class_name MapTextMesh
extends RefCounted

const CACHE_LIMIT := 32
# Size contour sampling for the map's font-size cap, rather than oversampling tiny glyphs.
const CONTOUR_STEP := MapTextData.FONT_SIZE / MapTextData.MAX_FONT_SIZE * 0.25

static var _cache: Dictionary[String, MapTextMesh] = {}
static var _natural_builder: TextMesh
static var _spaced_builder: TextMesh
static var _warming := false

var mesh := ArrayMesh.new()
var bounds: AABB
var spacing_width := 0.0
var _glyph_bounds: Dictionary[int, Vector2] = {}


static func for_text(text: String) -> MapTextMesh:
	if _cache.has(text):
		var cached := _cache[text]
		_cache.erase(text)
		_cache[text] = cached
		return cached
	_ensure_builders()
	# Keep the builders' fonts fixed so TextMesh retains its triangulated glyph cache.
	_natural_builder.text = text
	_spaced_builder.text = text
	var geometry := MapTextMesh.new()
	geometry.bounds = _natural_builder.get_aabb()
	geometry.spacing_width = _spaced_builder.get_aabb().size.x - geometry.bounds.size.x
	var arrays := _natural_builder.get_mesh_arrays()
	var spaced_arrays := _spaced_builder.get_mesh_arrays()
	var vertices: PackedVector3Array = arrays[Mesh.ARRAY_VERTEX]
	var spaced_vertices: PackedVector3Array = spaced_arrays[Mesh.ARRAY_VERTEX]
	var weights := PackedVector2Array()
	# Repeat x into all components so native packed-array operations can find each glyph's bounds.
	var x_transform := Transform3D(Basis(Vector3.ONE, Vector3.ZERO, Vector3.ZERO), Vector3.ZERO)
	var x_vertices: PackedVector3Array = x_transform * vertices
	var x_values := x_vertices.to_byte_array().to_float32_array()
	var start := 0
	while start < vertices.size():
		var gaps := roundi(spaced_vertices[start].x - vertices[start].x)
		# TextMesh emits glyphs in visual order. Their cumulative spacing is constant within
		# each glyph and increases between glyphs, so find the next boundary with a binary search.
		var low := start + 1
		var high := vertices.size()
		while low < high:
			var middle := (low + high) >> 1
			if roundi(spaced_vertices[middle].x - vertices[middle].x) == gaps:
				low = middle + 1
			else:
				high = middle
		var glyph_weights := PackedVector2Array()
		glyph_weights.resize(low - start)
		glyph_weights.fill(Vector2(gaps, 0.0))
		weights.append_array(glyph_weights)
		var glyph_x := x_values.slice(start * 3, low * 3)
		glyph_x.sort()
		geometry._glyph_bounds[gaps] = Vector2(glyph_x[0], glyph_x[-1])
		start = low
	arrays[Mesh.ARRAY_TEX_UV2] = weights
	geometry.mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)
	if _cache.size() >= CACHE_LIMIT:
		_cache.erase(_cache.keys()[0])
	_cache[text] = geometry
	return geometry


static func warm_up() -> void:
	if _warming:
		return
	_warming = true
	_ensure_builders()
	var tree := Engine.get_main_loop() as SceneTree
	# Prepare common glyphs one per frame, rather than triangulating an entire label on a click.
	for character: String in "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789":
		await tree.process_frame
		_natural_builder.text = character
		_spaced_builder.text = character
		_natural_builder.get_aabb()
		_spaced_builder.get_aabb()


static func _ensure_builders() -> void:
	if _natural_builder == null:
		_natural_builder = _make_builder(0)
		_spaced_builder = _make_builder(1)


static func _make_builder(spacing: int) -> TextMesh:
	var builder := TextMesh.new()
	builder.set_message_translation(false)
	builder.font = MapTextData.font_for_spacing(spacing)
	builder.font_size = MapTextData.FONT_SIZE
	builder.pixel_size = 1.0
	builder.depth = 0.0
	builder.curve_step = CONTOUR_STEP
	builder.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	return builder


func bounds_for_spacing(spacing: int) -> AABB:
	var minimum := INF
	var maximum := -INF
	for gaps: int in _glyph_bounds:
		var extent := _glyph_bounds[gaps] + Vector2.ONE * (gaps * spacing)
		minimum = minf(minimum, extent.x)
		maximum = maxf(maximum, extent.y)
	var result := bounds
	result.position.x = minimum
	result.size.x = maximum - minimum
	return result
