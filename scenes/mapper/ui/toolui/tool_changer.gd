extends HFlowContainer

const MAX_Y: int = 316 # we don't need to go bigger than this, since 

@onready var mapper: MapperRoot = MapperRoot._instance
@onready var brush: Button = $Brush # this is just a regular button to get a size reference
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
	mapper.tool.value = MapperRoot.Tool.get(button_name.to_upper())
	
func _unhandled_key_input(event: InputEvent) -> void:
	if event.is_action_pressed("tool_brush"):
		mapper.tool.value = MapperRoot.Tool.BRUSH
	elif event.is_action_pressed("tool_dice"):
		mapper.tool.value = MapperRoot.Tool.DICE

func try_resize() -> void:
	# TODO!!
	pass
