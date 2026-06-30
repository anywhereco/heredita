class_name Map
extends Node3D

static var _instance: Map

@export_range(1.0 / 32, 1, 1.0 / 32, "suffix:units/px") var pixel_size: float = 3.0 / 32

@onready var player_camera: Camera3D = $"../LocalPlayer/CameraPivot/CameraArm/PlayerCamera"
@onready var water: MeshInstance3D = $"../Water"

@onready var chunk_container_node: Node3D = $MapChunks
@onready var preview_plane: Sprite3D = $PreviewPlane
@onready var map_markings: MapMarkings = $MapMarkings

var default_target_color: Color = Color(1, 1, 1)

var chunk_creation_mutexes: Array[Mutex] = []
## Array[Array[bool]], x,y/z order
var chunks_edited: Array[Array] = []
## Array[Array[Sprite3D]], x,y/z order
var chunks: Array[Array] = []
## Array[Array[Image]], x,y/z order
var chunk_images: Array[Array] = []

var original_map: Image = preload("uid://do2qcumlvx0lo")
var preview_texture: Image = preload("uid://bug42uo2av8i2")
var original_map_size: Vector2
var original_map_size_exclusive: Vector2

var map_world_bounds: Rect2

var map_pos: ReactiveVector2 = ReactiveVector2.new(Vector2.INF)

var brush_shape_map: BrushShapeMap = BrushShapeMap.new()

var loaded := false

var pending_resync := ReactiveBool.new(false)

var queued_changes: Array[Dictionary] = []
var pending_markings: Array[Dictionary] = []

func is_in_bounding_box(test_point: Vector2, min_corner: Vector2, max_corner: Vector2) -> bool:
	return (
		test_point.x >= min_corner.x
		and test_point.x <= max_corner.x
		and test_point.y >= min_corner.y
		and test_point.y <= max_corner.y
	)


func world_space_to_map_space(world_pos: Vector2) -> Vector2:
	world_pos *= 1 / pixel_size
	world_pos += (original_map_size / 2)
	return world_pos


func map_space_to_world_space(_map_pos: Vector2) -> Vector2:
	_map_pos -= (original_map_size / 2)
	_map_pos *= pixel_size
	return _map_pos


func get_chunk_grid_coords(pos: Vector2) -> Vector2i:
	@warning_ignore("narrowing_conversion")
	return Vector2i(
		floorf(pos.x / Statics.CHUNK_SIZE_FLOAT), floorf(pos.y / Statics.CHUNK_SIZE_FLOAT)
	)


func get_chunk_relative_coords(pos: Vector2) -> Vector2:
	return Vector2(
		fposmod(pos.x, Statics.CHUNK_SIZE_FLOAT), fposmod(pos.y, Statics.CHUNK_SIZE_FLOAT)
	)


## If a position is invalid, returns Color(-1, -1, -1, -1).
func get_pixel_at(pos: Vector2) -> Color:
	pos = pos.floor()
	if not is_in_bounding_box(pos, Vector2.ZERO, original_map_size_exclusive):
		return Color(-1, -1, -1, -1)
	var chunk_coords := get_chunk_grid_coords(pos)
	var chunk: Image = chunk_images[chunk_coords.x][chunk_coords.y]
	return chunk.get_pixelv(Vector2i(get_chunk_relative_coords(pos)))


#func get_pixels_at(rect: Rect2i) -> Image:
#if not Rect2i(Vector2i.ZERO, original_map_size).encloses(rect):
#return
#rect.
#var chunk_coords := get_chunk_grid_coords(pos)
#var chunk: Image = chunks[chunk_coords.x][chunk_coords.y].texture.get_image()
#return chunk.get_pixelv(Vector2i(get_chunk_relative_coords(pos)))


func set_pixel_at(pos: Vector2, color: Color) -> bool:
	pos = pos.floor()
	if not is_in_bounding_box(pos, Vector2.ZERO, original_map_size_exclusive):
		return false
	var chunk_coords := get_chunk_grid_coords(pos)
	var chunk: Image = chunk_images[chunk_coords.x][chunk_coords.y]
	chunk.set_pixelv(Vector2i(get_chunk_relative_coords(pos)), color)
	chunks_edited[chunk_coords.x][chunk_coords.y] = true
	return true


func set_pixels_at(positions: PackedVector2Array, color: Color, offset: Vector2 = Vector2.ZERO) -> void:
	offset = offset.floor()
	for pos in positions:
		pos += offset
		if not is_in_bounding_box(pos, Vector2.ZERO, original_map_size_exclusive):
			continue
		var chunk_coords := get_chunk_grid_coords(pos)
		var chunk: Image = chunk_images[chunk_coords.x][chunk_coords.y]
		chunk.set_pixelv(Vector2i(get_chunk_relative_coords(pos)), color)
		chunks_edited[chunk_coords.x][chunk_coords.y] = true


func set_pixels_at_targeted(
	positions: PackedVector2Array, color: Color, target: Color, offset: Vector2 = Vector2.ZERO
) -> void:
	for pos in positions:
		pos += offset
		if not is_in_bounding_box(pos, Vector2.ZERO, original_map_size_exclusive):
			continue
		var chunk_coords := get_chunk_grid_coords(pos)
		var chunk: Image = chunk_images[chunk_coords.x][chunk_coords.y]
		var relative_coords := get_chunk_relative_coords(pos)
		if chunk.get_pixelv(relative_coords).is_equal_approx(target):
			chunk.set_pixelv(Vector2i(get_chunk_relative_coords(pos)), color)
			chunks_edited[chunk_coords.x][chunk_coords.y] = true


func set_pixels_at_land(
	positions: PackedVector2Array, color: Color, offset: Vector2 = Vector2.ZERO
) -> void:
	for pos in positions:
		pos += offset
		if not is_in_bounding_box(pos, Vector2.ZERO, original_map_size_exclusive):
			continue
		var chunk_coords := get_chunk_grid_coords(pos)
		var chunk: Image = chunk_images[chunk_coords.x][chunk_coords.y]
		var relative_coords := get_chunk_relative_coords(pos)
		if chunk.get_pixelv(relative_coords).a > 0:
			chunk.set_pixelv(Vector2i(get_chunk_relative_coords(pos)), color)
			chunks_edited[chunk_coords.x][chunk_coords.y] = true


func set_pixels_at_maybe_targeted(
	positions: PackedVector2Array, color: Color, target: Color, targeted: bool, offset: Vector2 = Vector2.ZERO
) -> void:
	if targeted:
		set_pixels_at_targeted(positions, color, target, offset)
	else:
		set_pixels_at_land(positions, color, offset)
		

func set_pixels_at_map_pos_targeted(
	positions: PackedVector2Array, color: Color, target: Color, targeted: bool = true
) -> void:
	set_pixels_at_maybe_targeted(positions, color, target, targeted, Vector2(Vector2i(map_pos.value)))


func get_map_as_image() -> Image:
	@warning_ignore("narrowing_conversion")
	var map_image: Image = Image.create_empty(
		original_map_size.x, original_map_size.y, false, Image.FORMAT_RGBA8
	)
	for x in len(chunk_images):
		var chunk_column: Array = chunk_images[x]
		for y in len(chunk_column):
			var chunk: Image = chunk_column[y]
			map_image.blit_rect(
				chunk,
				Rect2i(0, 0, chunk.get_width(), chunk.get_height()),
				Vector2i(x * Statics.CHUNK_SIZE, y * Statics.CHUNK_SIZE)
			)
	return map_image


func get_data() -> MapData:
	var data := MapData.new()
	data.image = get_map_as_image()
	if is_node_ready():
		data.markings = map_markings.serialize_markings()
	else:
		data.markings = pending_markings
	return data


func set_data(data: MapData) -> void:
	original_map = data.image
	if is_node_ready():
		map_markings.set_markings(data.markings)
	else:
		pending_markings = data.markings
	original_map_size = original_map.get_size()
	original_map_size_exclusive = original_map_size - Vector2(1, 1)
	if not State.client.operator or loaded:
		load_from_original()
	if pending_resync.value:
		return


func _init() -> void:
	_instance = self


func load_from_original() -> void:
	preview_plane.texture.set_image(preview_texture)
	reset_chunks()
	water.mesh.size = map_space_to_world_space(Vector2.ZERO).abs() * 2
	map_world_bounds = Rect2(
		map_space_to_world_space(Vector2.ZERO), map_space_to_world_space(Vector2.ZERO).abs() * 2
	)


func reset_chunks() -> void:
	chunk_creation_mutexes.clear()
	chunks_edited.clear()
	chunks.clear()
	chunk_images.clear()
	if chunk_container_node.get_children().size() > 0:
		for child in chunk_container_node.get_children():
			child.queue_free()
	original_map_size = original_map.get_size()
	original_map_size_exclusive = original_map_size - Vector2(1, 1)
	var row_size := ceili(original_map_size.x/Statics.CHUNK_SIZE)
	var column_size := ceili(original_map_size.y/Statics.CHUNK_SIZE)
	for chunk_row in row_size:
		var chunk_array := []
		var chunk_edited_array := []
		var chunk_image_array := []
		chunk_array.resize(column_size)
		chunk_edited_array.resize(column_size)
		chunk_image_array.resize(column_size)
		chunks.append(chunk_array)
		chunks_edited.append(chunk_edited_array)
		chunk_images.append(chunk_image_array)
		chunk_creation_mutexes.append(Mutex.new())
	var chunk_count := row_size * ceili(original_map_size.y/Statics.CHUNK_SIZE)
	var id := WorkerThreadPool.add_group_task(initialize_chunk.bind(row_size), chunk_count)
	WorkerThreadPool.wait_for_group_task_completion(id)
	add_chunks()
	@warning_ignore("unsafe_call_argument")
	brightness_change(Settings.get_reactive("map_brightness"))
	loaded = true
	

func initialize_chunk(index: int, row_size: int) -> void:
	var x_idx := index % row_size
	var y_idx := floori(index / (row_size as float))
	#prints(index, row_size, x_idx, y_idx)
	var x := x_idx * Statics.CHUNK_SIZE
	var y := y_idx * Statics.CHUNK_SIZE
	var chunk_coords := Rect2i(Vector2i(x, y), Vector2i(Statics.CHUNK_SIZE, Statics.CHUNK_SIZE))
	var img := original_map.get_region(chunk_coords)
	#Image.create_empty(Statics.CHUNK_SIZE, Statics.CHUNK_SIZE, false, original_map.get_format())
	#img.blit_rect(original_map, chunk_coords, Vector2i.ZERO)
	var chunk := Sprite3D.new()
	chunk.texture = ImageTexture.create_from_image(img)
	chunk.axis = Vector3.Axis.AXIS_Y
	chunk.double_sided = false
	@warning_ignore("integer_division")
	var center := map_space_to_world_space(
		Vector2(x + (Statics.CHUNK_SIZE / 2), y + (Statics.CHUNK_SIZE / 2))
	)
	chunk.position = Vector3(center.x, 0, center.y)
	chunk.name = "MapChunk%d:%d" % [x_idx, y_idx]
	chunk.pixel_size = pixel_size
	chunk.texture_filter = BaseMaterial3D.TEXTURE_FILTER_NEAREST
	chunk_creation_mutexes[x_idx].lock()
	chunks[x_idx][y_idx] = chunk
	chunks_edited[x_idx][y_idx] = false
	chunk_images[x_idx][y_idx] = img
	chunk_creation_mutexes[x_idx].unlock()


func add_chunks() -> void:
	for row in chunks:
		for chunk: Sprite3D in row:
			chunk_container_node.add_child(chunk)


func _ready() -> void:
	Settings.get_reactive("map_brightness").value_changed.connect(brightness_change)
	if not pending_markings.is_empty():
		map_markings.set_markings(pending_markings)
		pending_markings.clear()
	if State.client.operator:
		load_from_original()
	preview_plane.pixel_size = pixel_size


func brightness_change(brightness: ReactiveFloat) -> void:
	for chunk: Sprite3D in chunk_container_node.get_children():
		chunk.modulate = Color(brightness.value, brightness.value, brightness.value, 1)


func update_map_pos() -> void:
	var mouse_position := get_viewport().get_mouse_position() #VirtualMouse._instance.position
	# The map is at zero on the Y axis
	var intersect: Variant = Plane.PLANE_XZ.intersects_ray(
		player_camera.project_ray_origin(mouse_position),
		player_camera.project_ray_normal(mouse_position)
	)
	if intersect is not Vector3:
		return
	@warning_ignore("unsafe_call_argument")
	var intersect_pos: Vector2 = Vector2(intersect.x, intersect.z)
	var prev_pos := map_pos.value
	map_pos.value = world_space_to_map_space(intersect_pos)
	if not is_in_bounding_box(
		map_pos.value, Vector2(-30, -30), original_map_size + Vector2(30, 30)
	):
		return
	if (
		Vector2i(prev_pos.floor()) != Vector2i(map_pos.value.floor())
		and MapperRoot._instance.tool.value == MapperRoot.Tool.BRUSH
	):
		update_brush_preview()


func update_brush_preview() -> void:
	var clipped := map_space_to_world_space(Vector2i(map_pos.value))
	clipped = clipped + Vector2(pixel_size * 1 / 2, pixel_size * 1 / 2)
	preview_plane.position = Vector3(clipped.x, 0, clipped.y)
	MapperRoot._instance.brush._update_brush()


func resync() -> void:
	pending_resync.value = true
	State.client.send("map_resync")

func finish_resync() -> void:
	pending_resync.value = false
	for event in queued_changes:
		get_map_update(event)

func get_map_update(details: Dictionary) -> void:
	var type: String = details["type"]
	if pending_resync.value:
		queued_changes.append(details)
		return
	if type == "brush":
		if not details.has("size")\
		or not details.has("paint_color")\
		or not details.has("target_color")\
		or not details.has("pos")\
		or not details.has("targeted")\
		or not Verify.is_numeric(details["size"])\
		or not Verify.array_is_type(details["paint_color"], TYPE_FLOAT)\
		or not Verify.array_is_type(details["target_color"], TYPE_FLOAT)\
		or not Verify.array_is_type(details["pos"], TYPE_FLOAT)\
		or not typeof(details["targeted"]) == TYPE_BOOL:
			return
		@warning_ignore("unsafe_call_argument")
		Map._instance.set_pixels_at_maybe_targeted(
			brush_shape_map.get_vec2s(details["size"]),
			ISUtil.to_color(details["paint_color"]),
			ISUtil.to_color(details["target_color"]),
			details["targeted"],
			ISUtil.to_vec2(details["pos"])
		)
	elif type == "marking":
		map_markings.apply_update(details)


func _process(_delta: float) -> void:
	update_map_pos()
	if MapperRoot._instance.tool.value == MapperRoot.Tool.BRUSH:
		preview_plane.visible = true
	else:
		preview_plane.visible = false
	for x in range(0, chunks_edited.size()):
		for y in range(0, chunks_edited[0].size()):
			if chunks_edited[x][y] == false:
				continue
			chunks[x][y].texture.update(chunk_images[x][y])
			chunks_edited[x][y] = false


func _unhandled_input(event: InputEvent) -> void:
	MapperRoot._instance.process_tool_use(event)
