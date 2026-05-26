extends HFlowContainer

const MAX_Y: int = 316  # we don't need to go bigger than this, since

@onready var mapper: MapperRoot = MapperRoot._instance
@onready var brush: Button = $Brush  # this is just a regular button to get a size reference
@onready var left_items: VBoxContainer = $"../../.."


func _ready() -> void:
	#State.display.root_window_resized.connect(try_resize)
	try_resize()
	connect_buttons_recursively(self)


func connect_buttons_recursively(node: Node) -> void:
	for child in node.get_children():
		if child is Button:
			child.pressed.connect(_on_button_pressed.bind(child.name))
		else:
			connect_buttons_recursively(child)


func _on_button_pressed(button_name: String) -> void:
	var tool: MapperRoot.Tool = MapperRoot.Tool.get(button_name.to_upper())
	if mapper.tool.value == tool:
		mapper.tool.value = MapperRoot.Tool.NONE
		(find_child(button_name) as Button).button_pressed = false
	else:
		mapper.tool.value = tool
		(find_child(button_name) as Button).button_pressed = true


func _unhandled_key_input(event: InputEvent) -> void:
	if event.is_action_pressed("tool_brush"):
		_on_button_pressed("Brush")
	elif event.is_action_pressed("tool_dice"):
		_on_button_pressed("Dice")
	elif event.is_action_pressed("tool_marking"):
		_on_button_pressed("Marking")


func try_resize() -> void:
	# TODO!!
	pass
