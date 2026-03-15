extends Control

@onready var mapper := MapperRoot._instance

var prev_name: String = "none"


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	mapper.tool.value_changed.connect(new_tool)


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta: float) -> void:
	pass


func new_tool(id: ReactiveInt) -> void:
	var tool_name: String = MapperRoot.Tool.keys()[id.value].to_lower()
	var prev_element: Node = find_child(prev_name, false)
	var new_element: Node = find_child(tool_name, false)

	if prev_element != null:
		prev_element.hide()

	if new_element != null:
		new_element.show()
		prev_name = tool_name
	else:
		push_error('Tool "%s" doesn\'t have a UI!' % tool_name)
