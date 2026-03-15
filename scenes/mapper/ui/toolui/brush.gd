class_name BrushUI
extends VBoxContainer

@onready var paint_label: Label = $HBoxContainer2/Paint/Label
@onready var target_label: Label = $HBoxContainer2/Target/Label

@onready var paint_picker: HereditaColorPicker = $HBoxContainer2/Paint/ColorPicker
@onready var target_picker: HereditaColorPicker = $HBoxContainer2/Target/ColorPicker

@onready var size_controller: BrushSizeController = $HBoxContainer/BrushSize

const PRO_450 = preload("uid://hwc3xdnlf3ke")
const PRO_650 = preload("uid://dci33svbxkhv6")


func _ready() -> void:
	pass  # Replace with function body.


func _process(_delta: float) -> void:
	pass


func _unhandled_key_input(event: InputEvent) -> void:
	if MapperRoot._instance.tool.value != MapperRoot.Tool.BRUSH:
		return

	if event.is_action_pressed("pick_paint"):
		paint_label.label_settings.font = PRO_650
	if event.is_action_released("pick_paint"):
		paint_label.label_settings.font = PRO_450
	if event.is_action_pressed("pick_target"):
		target_label.label_settings.font = PRO_650
	if event.is_action_released("pick_target"):
		target_label.label_settings.font = PRO_450
