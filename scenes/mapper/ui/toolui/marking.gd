class_name MarkingUI
extends TabContainer

signal edit_requested(id: String, changes: Dictionary)

@onready var create_city_button: Button = $Create/HBoxContainer/City
@onready var create_fort_button: Button = $Create/HBoxContainer/Fort
@onready var create_color_picker: HereditaColorPicker = $Create/ColorPicker
@onready var delete_city_checkbox: CheckBox = $Delete/City
@onready var delete_fort_checkbox: CheckBox = $Delete/Fort
@onready var edit_title: Label = $Edit/Label2
@onready var edit_color_picker: HereditaColorPicker = $Edit/HBoxContainer/MarginContainer/ColorPicker
@onready var edit_name: LineEdit = $Edit/HBoxContainer/VBoxContainer/LineEdit
@onready var edit_name_label: Label = $Edit/HBoxContainer/VBoxContainer/Label2

var create_type := "city"
var selected_marking_id := ""
var suppress_edit_signals := false


func _ready() -> void:
	create_city_button.toggle_mode = true
	create_fort_button.toggle_mode = true
	create_city_button.button_pressed = true
	create_city_button.pressed.connect(func() -> void: set_create_type("city"))
	create_fort_button.pressed.connect(func() -> void: set_create_type("fort"))
	create_color_picker.color.value = Color(0.85, 0.2, 0.15)
	delete_city_checkbox.button_pressed = true
	delete_fort_checkbox.button_pressed = true
	edit_color_picker.color.value_changed.connect(_edit_color_changed)
	edit_name.text_submitted.connect(_edit_name_submitted.unbind(1))
	edit_name.focus_exited.connect(_edit_name_submitted)
	set_selected(null)


func set_create_type(type: String) -> void:
	create_type = type
	create_city_button.button_pressed = type == "city"
	create_fort_button.button_pressed = type == "fort"


func delete_types() -> Array[String]:
	var types: Array[String] = []
	if delete_city_checkbox.button_pressed:
		types.append("city")
	if delete_fort_checkbox.button_pressed:
		types.append("fort")
	return types


func set_selected(marking: MapMarkings.MapObject) -> void:
	suppress_edit_signals = true
	if marking == null:
		selected_marking_id = ""
		edit_title.text = "Select a marking"
		edit_name.editable = false
		edit_name.text = ""
		edit_name.placeholder_text = ""
		edit_name_label.text = "Name"
		edit_color_picker.modulate = Color(1, 1, 1, 0.45)
	else:
		selected_marking_id = marking.id
		edit_title.text = "Edit this %s" % marking.marking_type
		edit_name.editable = true
		edit_name.text = marking.name
		edit_name.placeholder_text = "%s name..." % marking.marking_type.capitalize()
		edit_name_label.text = "%s name" % marking.marking_type.capitalize()
		edit_color_picker.color.value = marking.color
		edit_color_picker.modulate = Color.WHITE
	suppress_edit_signals = false


func _edit_color_changed(color: ReactiveColor) -> void:
	if suppress_edit_signals or selected_marking_id.is_empty():
		return
	edit_requested.emit(selected_marking_id, {"color": ISUtil.from_color(color.value)})


func _edit_name_submitted() -> void:
	if suppress_edit_signals or selected_marking_id.is_empty():
		return
	edit_requested.emit(selected_marking_id, {"name": edit_name.text.left(64)})
