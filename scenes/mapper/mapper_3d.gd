class_name MapperRoot
extends Node3D

enum Tool {
	NONE,
	BRUSH,
	FILL,
	LINE,
	PICK,
	INSPECT,
	PAN,
	MARKING,
	SELECT
}

static var _instance: MapperRoot

var tool := ReactiveInt.new(Tool.NONE)

var brush: BrushTool = BrushTool.new()

# May be empty
var map_data_compressed: PackedByteArray
var map_data_uncompr_size: int

func _brush_size_changed(_reactive: ReactiveInt) -> void:
	brush.size = UIRoot._instance.brush_ui.size_controller.brush_size.value
	Map._instance.preview_plane.texture.update(brush.get_image_for_brush())

func _tool_changed(reactive: ReactiveInt) -> void:
	if reactive.value == Tool.NONE:
		VirtualMouse._instance.set_action_tool(VirtualMouse.Action.DEFAULT)
	elif reactive.value == Tool.BRUSH:
		VirtualMouse._instance.set_action_tool(VirtualMouse.Action.BRUSH)

func _init() -> void:
	_instance = self

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	TopLevel.ui = $UI
	tool.value_changed.connect(_tool_changed)
	brush._map_ready()
	if State.client:
		State.client.message_received.connect(get_map_update)
		State.client.binary_message_received.connect(sync_map)
		State.client.connection_closed.connect(closed)

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	brush._process(delta)

func process_tool_use(event: InputEvent) -> void:
	match tool.value:
		Tool.NONE:
			return
		Tool.BRUSH:
			brush.brush_events(event)
		_:
			push_error("Tool \"%s\" doesn't have code to handle events!" % MapperRoot.Tool.keys()[tool.value].to_lower())
			return

func get_map_update(event: String, _player_id: int, details: Variant) -> void:
	if event == "map_update":
		Map._instance.get_map_update(details as Dictionary)

func sync_map(event: int, _player_id: int, _flags: int, details: PackedByteArray) -> void:
	if event == ISUtil.BinaryEvents.SYNC_MAP_SIZE:
		map_data_uncompr_size = details.decode_u32(0)
	if event == ISUtil.BinaryEvents.SYNC_MAP:
		map_data_compressed.append_array(details)
	if event == ISUtil.BinaryEvents.SYNC_MAP_END:
		map_data_compressed.append_array(details)
		var decomp := map_data_compressed.decompress(map_data_uncompr_size, FileAccess.COMPRESSION_FASTLZ)
		Map._instance.set_data(MapData.deserialize(decomp))

func closed() -> void:
	if not is_inside_tree(): #if we exited manually
		return
	VirtualMouse._instance.set_action_tool(VirtualMouse.Action.DEFAULT)
	var menu: Node2D = preload("res://scenes/main_menu/main.tscn").instantiate()
	get_tree().current_scene.queue_free()
	get_tree().root.add_child(menu)
	TopLevel.ui = menu.get_node("Foreground") #do this manually since it hasn't loaded yet
	InfoPrompt.prompt("The room was closed.")
	#eventually have a more detailed message if you're kicked/banned/etc though idk how they'd send that
	get_tree().current_scene = menu
