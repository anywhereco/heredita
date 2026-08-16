class_name UIRoot
extends CanvasLayer

static var _instance: UIRoot

@onready var brush_ui: BrushUI = find_child("ToolUIContainer").find_child("brush", false)
@onready var dice_ui: DiceUI = find_child("ToolUIContainer").find_child("dice", false)
@onready var marking_ui: MarkingUI = find_child("ToolUIContainer").find_child("marking", false)


func _init() -> void:
	_instance = self


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("enable_cinematic_freecam"):
		visible = not visible
