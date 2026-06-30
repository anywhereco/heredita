class_name MapperRoot
extends Node3D

enum Tool {
	NONE,
	BRUSH,
	DICE,
	FILL,
	LINE,
	PICK,
	INSPECT,
	PAN,
	MARKING,
}

static var _instance: MapperRoot

var tool := ReactiveInt.new(Tool.NONE)

var brush: BrushTool = BrushTool.new()
var dice: DiceTool = DiceTool.new()
var marking: MarkingTool = MarkingTool.new()

# May be empty
var map_data_compressed: PackedByteArray
var map_data_uncompr_size: int

func _brush_size_changed(_reactive: ReactiveInt) -> void:
	brush.size = UIRoot._instance.brush_ui.size_controller.brush_size.value
	Map._instance.preview_plane.texture.update(brush.get_image_for_brush())


func _tool_changed(reactive: ReactiveInt) -> void:
	if reactive.value == Tool.NONE:
		VirtualMouse._instance.set_action_tool(VirtualMouse.Action.DEFAULT)
		pass
	elif reactive.value == Tool.BRUSH:
		VirtualMouse._instance.set_action_tool(VirtualMouse.Action.BRUSH)
		pass
	elif reactive.value == Tool.DICE:
		VirtualMouse._instance.set_action_tool(VirtualMouse.Action.DICE)
		pass
	elif reactive.value == Tool.MARKING:
		VirtualMouse._instance.set_action_tool(VirtualMouse.Action.DEFAULT)
		pass


func _init() -> void:
	_instance = self


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	TopLevel.ui = $UI
	tool.value_changed.connect(_tool_changed)
	brush._map_ready()
	dice._map_ready()
	marking._map_ready()
	if State.client:
		State.client.message_received.connect(message_recieved)
		State.client.binary_message_received.connect(binary_message_recieved)
		State.client.connection_closed.connect(closed)


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	brush._process(delta)
	dice._process(delta)


func process_tool_use(event: InputEvent) -> void:
	match tool.value:
		Tool.NONE:
			return
		Tool.BRUSH:
			brush.brush_events(event)
		Tool.DICE:
			dice.dice_events(event)
		Tool.MARKING:
			marking.marking_events(event)
		_:
			push_error(
				(
					'Tool "%s" doesn\'t have code to handle events!'
					% MapperRoot.Tool.keys()[tool.value].to_lower()
				)
			)
			return


func message_recieved(event: String, _player_id: int, details: Variant) -> void:
	if event == "map_update":
		Map._instance.get_map_update(details as Dictionary)
	if event == "calendar_sync":
		TimekeepingUI._inst.calendar_sync(details as Dictionary)


func binary_message_recieved(event: int, _player_id: int, _flags: int, details: PackedByteArray) -> void:
	if event == ISUtil.BinaryEvents.SYNC_MAP:
		Map._instance.set_data(MapData.deserialize(details))
		Map._instance.finish_resync()
	elif event == ISUtil.BinaryEvents.FORCE_RESYNC_MAP:
		Map._instance.pending_resync.value = true
		Map._instance.set_data(MapData.deserialize(details))
		Map._instance.finish_resync()


func closed() -> void:
	if not is_inside_tree():  #if we exited manually
		return
	VirtualMouse._instance.set_action_tool(VirtualMouse.Action.DEFAULT)
	var menu: Node2D = load("res://scenes/main_menu/main.tscn").instantiate()
	get_tree().current_scene.queue_free()
	get_tree().root.add_child(menu)
	TopLevel.ui = menu.get_node("Foreground")  #do this manually since it hasn't loaded yet
	#this code doesnt work because the client gets a close reason of 1002 for some reason
	#var connection_string := State.client.socket.get_close_reason()
	#if not connection_string:
	#connection_string = "The connection was closed."
	#InfoPrompt.prompt(connection_string)
	InfoPrompt.prompt("The connection was closed.")
	#eventually have a more detailed message if you're kicked/banned/etc though idk how they'd send that
	get_tree().current_scene = menu
