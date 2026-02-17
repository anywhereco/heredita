class_name Map
extends Node3D

static var _instance: Map

const CHUNK_SIZE: int = 256
const CHUNK_SIZE_FLOAT: float = float(CHUNK_SIZE)

@export_range(1.0/16, 1, 1.0/16) var pixel_size: float = 1.0/8

@onready var player_camera: Camera3D = $"../LocalPlayer/CameraPivot/CameraArm/PlayerCamera"
@onready var water: MeshInstance3D = $"../Water"

@onready var chunk_container_node: Node3D = $MapChunks
@onready var preview_plane: Sprite3D = $PreviewPlane

var default_target_color: Color = Color(1,1,1)

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

func is_in_bounding_box(test_point: Vector2, min_corner: Vector2, max_corner: Vector2) -> bool:
	return (test_point.x >= min_corner.x and 
			test_point.x <= max_corner.x and
			test_point.y >= min_corner.y and
			test_point.y <= max_corner.y)

func world_space_to_map_space(world_pos: Vector2) -> Vector2:
	world_pos *= 1/pixel_size
	world_pos += (original_map_size/2)
	return world_pos
	
func map_space_to_world_space(_map_pos: Vector2) -> Vector2:
	_map_pos -= (original_map_size/2)
	_map_pos *= pixel_size
	return _map_pos

func get_chunk_grid_coords(pos: Vector2) -> Vector2i:
	@warning_ignore("narrowing_conversion")
	return Vector2i(floorf(pos.x/CHUNK_SIZE_FLOAT), floorf(pos.y/CHUNK_SIZE_FLOAT))

func get_chunk_relative_coords(pos: Vector2) -> Vector2:
	return Vector2(fposmod(pos.x, CHUNK_SIZE_FLOAT), fposmod(pos.y, CHUNK_SIZE_FLOAT))

## If a position is invalid, returns Color(-1, -1, -1, -1).
func get_pixel_at(pos: Vector2) -> Color:
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
	if not is_in_bounding_box(pos, Vector2.ZERO, original_map_size_exclusive):
		return false
	var chunk_coords := get_chunk_grid_coords(pos)
	var chunk: Image = chunk_images[chunk_coords.x][chunk_coords.y]
	chunk.set_pixelv(Vector2i(get_chunk_relative_coords(pos)), color)
	chunks_edited[chunk_coords.x][chunk_coords.y] = true
	return true

func set_pixels_at(positions: PackedVector2Array, color: Color) -> void:
	for pos in positions:
		if not is_in_bounding_box(pos, Vector2.ZERO, original_map_size_exclusive):
			continue
		var chunk_coords := get_chunk_grid_coords(pos)
		var chunk: Image = chunk_images[chunk_coords.x][chunk_coords.y]
		chunk.set_pixelv(Vector2i(get_chunk_relative_coords(pos)), color)
		chunks_edited[chunk_coords.x][chunk_coords.y] = true

func set_pixels_at_targeted(positions: PackedVector2Array, color: Color, target: Color, offset: Vector2 = Vector2.ZERO) -> void:
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
			
func set_pixels_at_map_pos_targeted(positions: PackedVector2Array, color: Color, target: Color) -> void:
	set_pixels_at_targeted(positions, color, target, Vector2(Vector2i(map_pos.value)))

func get_map_as_image() -> Image:
	@warning_ignore("narrowing_conversion")
	var map_image: Image = Image.create_empty(original_map_size.x, original_map_size.y, false, Image.FORMAT_RGBA8)
	for x in len(chunk_images):
		var chunk_column: Array = chunk_images[x]
		for y in len(chunk_column):
			var chunk: Image = chunk_column[y]
			map_image.blit_rect(chunk, Rect2i(0, 0, chunk.get_width(), chunk.get_height()), Vector2i(x*CHUNK_SIZE,y*CHUNK_SIZE))
	return map_image

const PACKAGE_VERSION = 0

func package() -> Dictionary[String, Variant]:
	var map_image := get_map_as_image()
	return {image = map_image.get_data(),
			image_size = map_image.get_size()}
	
func serialize() -> PackedByteArray:
	var serialized_map: PackedByteArray = var_to_bytes(package())
	serialized_map.insert(0,PACKAGE_VERSION)
	return serialized_map
	
func deserialize(serialized: PackedByteArray) -> void:
	var package_version := serialized[0]
	serialized.remove_at(0)
	if package_version >= 0:
		var map_data: Dictionary[String, Variant] = bytes_to_var(serialized)
		var image_size: Vector2 = map_data["image_size"]
		original_map = Image.create_from_data(image_size.x,image_size.y,false,Image.FORMAT_RGBA8,map_data["image"])

func _init() -> void:
	_instance = self

func _ready() -> void:
	preview_plane.texture.set_image(preview_texture)
	
	original_map_size = original_map.get_size()
	original_map_size_exclusive = original_map_size - Vector2(1, 1)
	for x: int in range(0, original_map_size.x, CHUNK_SIZE):
		for y: int in range(0, original_map_size.y, CHUNK_SIZE):
			@warning_ignore("integer_division")
			var x_idx := x/CHUNK_SIZE
			@warning_ignore("integer_division")
			var y_idx := y/CHUNK_SIZE
			var chunk_coords := Rect2i(Vector2i(x,y), Vector2i(CHUNK_SIZE, CHUNK_SIZE))
			var img := original_map.get_region(chunk_coords)
			#Image.create_empty(CHUNK_SIZE, CHUNK_SIZE, false, original_map.get_format())
			#img.blit_rect(original_map, chunk_coords, Vector2i.ZERO)
			var chunk := Sprite3D.new()
			chunk.texture = ImageTexture.create_from_image(img)
			chunk.axis = Vector3.Axis.AXIS_Y
			chunk.double_sided = false
			@warning_ignore("integer_division")
			var center := map_space_to_world_space(Vector2(x+(CHUNK_SIZE/2), y+(CHUNK_SIZE/2)))
			chunk.position = Vector3(center.x, 0, center.y)
			chunk.name = "MapChunk%d:%d" % [x_idx, y_idx]
			chunk.pixel_size = pixel_size
			chunk.texture_filter = BaseMaterial3D.TEXTURE_FILTER_NEAREST
			chunk_container_node.add_child(chunk)
			if chunks.size() <= x_idx:
				chunks.append([])
				chunks_edited.append([])
				chunk_images.append([])
			chunks.get(x_idx).insert(y_idx, chunk)
			chunks_edited.get(x_idx).insert(y_idx, false)
			chunk_images.get(x_idx).insert(y_idx, img)
	water.mesh.size = map_space_to_world_space(Vector2.ZERO).abs() * 2
	map_world_bounds = Rect2(map_space_to_world_space(Vector2.ZERO), map_space_to_world_space(Vector2.ZERO).abs() * 2)

func update_map_pos() -> void:
	var mouse_position := VirtualMouse._instance.position
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
	if not is_in_bounding_box(map_pos.value, Vector2(-30, -30), original_map_size + Vector2(30, 30)):
		return
	if Vector2i(prev_pos) != Vector2i(map_pos.value) and MapperRoot._instance.tool.value == MapperRoot.Tool.BRUSH:
		update_brush_preview()

func update_brush_preview() -> void:
	var clipped := map_space_to_world_space(Vector2i(map_pos.value))
	clipped = clipped + Vector2(pixel_size*1/2, pixel_size*1/2)
	preview_plane.position = Vector3(clipped.x, 0, clipped.y)
	MapperRoot._instance.brush._update_brush()

func get_map_update(details: Dictionary) -> void:
	var type: String = details["type"]
	if type == "brush":
		Map._instance.set_pixels_at_targeted(
			brush_shape_map.get_vec2s(details["size"]),
			ISUtil.to_color(details["paint_color"]),
			ISUtil.to_color(details["target_color"]),
			ISUtil.to_vec2(details["pos"]))

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
