class_name BrushUI
extends HBoxContainer

@onready var paint_label: Label = $HBoxContainer2/Paint/Label
@onready var target_label: Label = $HBoxContainer2/Target/Label

@onready var paint_picker: HereditaColorPicker = $HBoxContainer2/Paint/ColorPicker
@onready var target_picker: HereditaColorPicker = $HBoxContainer2/Target/ColorPicker
@onready var paint_water_checkbox: CheckBox = $HBoxContainer2/Paint/PaintWater
@onready var target_water_checkbox: CheckBox = $HBoxContainer2/Target/TargetWater

@onready var size_controller: BrushSizeController = $HBoxContainer/BrushSize
@onready var untargeted_checkbox: CheckBox = $HBoxContainer2/Target/UntargetedCheckbox

const PRO_450 = preload("uid://hwc3xdnlf3ke")
const PRO_650 = preload("uid://dci33svbxkhv6")


func _ready() -> void:
	paint_water_checkbox.toggled.connect(_set_water.bind(paint_picker.color))
	target_water_checkbox.toggled.connect(_set_water.bind(target_picker.color))
	target_water_checkbox.toggled.connect(
		func(is_water: bool) -> void:
			if is_water:
				untargeted_checkbox.button_pressed = false
	)
	paint_picker.color.value_changed.connect(_update_water_options.unbind(1))
	target_picker.color.value_changed.connect(_update_water_options.unbind(1))
	_update_water_options()
	_update_water_privileges()
	if State.client:
		State.client.message_received.connect(_client_message)


func _client_message(event: String, _player_id: int, _details: Variant) -> void:
	if event == "is2_player_operator_status_update":
		_update_water_privileges()


func _update_water_privileges() -> void:
	var allowed := BrushTool.can_paint_water()
	paint_water_checkbox.visible = allowed
	target_water_checkbox.visible = allowed
	if not allowed:
		if paint_picker.color.value.a != 1.0:
			_set_water(false, paint_picker.color)
		if target_picker.color.value.a != 1.0:
			_set_water(false, target_picker.color)


func _set_water(is_water: bool, color: ReactiveColor) -> void:
	var value := color.value
	value.a = 0.0 if is_water else 1.0
	color.value = value


func _update_water_options() -> void:
	paint_water_checkbox.set_pressed_no_signal(paint_picker.color.value.a == 0.0)
	target_water_checkbox.set_pressed_no_signal(target_picker.color.value.a == 0.0)


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
