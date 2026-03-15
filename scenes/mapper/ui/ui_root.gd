class_name UIRoot
extends CanvasLayer

static var _instance: UIRoot

@onready var brush_ui: BrushUI = find_child("ToolUIContainer").find_child("brush", false)
@onready var dice_ui: DiceUI = find_child("ToolUIContainer").find_child("dice", false)


func _init() -> void:
	_instance = self
