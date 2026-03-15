extends PanelContainer

@onready var mapper: MapperRoot = MapperRoot._instance

@onready var title: Label = %Title


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	mapper.tool.value_changed.connect(new_tool)


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta: float) -> void:
	pass


func new_tool(id: ReactiveInt) -> void:
	var tool_name: String = MapperRoot.Tool.keys()[id.value].capitalize()
	title.text = tool_name
