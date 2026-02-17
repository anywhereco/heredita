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
	Prompts.override_ui = $UI
	tool.value_changed.connect(_tool_changed)
	brush._map_ready()
	if State.client:
		State.client.message_received.connect(get_map_update)
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

func get_map_update(event: String, player_id: int, details: Variant) -> void:
	if event == "map_update":
		Map._instance.get_map_update(details as Dictionary)

func closed() -> void:
	if not is_inside_tree(): #if we exited manually
		return
	VirtualMouse._instance.set_action_tool(VirtualMouse.Action.DEFAULT)
	var menu: Node2D = preload("res://scenes/main_menu/main.tscn").instantiate()
	get_tree().current_scene.queue_free()
	get_tree().root.add_child(menu)
	Prompts.override_ui = menu.get_node("Foreground") #do this manually since it hasn't loaded yet
	InfoPrompt.prompt("The room was closed.")
	#eventually have a more detailed message if you're kicked/banned/etc though idk how they'd send that
	get_tree().current_scene = menu
