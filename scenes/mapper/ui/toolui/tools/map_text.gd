class_name MapTextUI
extends TabContainer

signal settings_changed
signal straighten_requested

@onready var create_content: LineEdit = $Create/Content
@onready var create_size: SpinBox = $Create/Style/Size
@onready var create_color: ColorPickerButton = $Create/Style/Color
@onready var edit_content: LineEdit = $Edit/ContentStraightenBox/Content
@onready var edit_size: SpinBox = $Edit/Style/Size
@onready var edit_color: ColorPickerButton = $Edit/Style/Color
@onready var edit_title: Label = $Edit/Title
@onready var straighten_button: Button = $Edit/ContentStraightenBox/Straighten

var content: LineEdit:
	get:
		return create_content if current_tab == 0 else edit_content
var font_size: SpinBox:
	get:
		return create_size if current_tab == 0 else edit_size
var color_picker: ColorPickerButton:
	get:
		return create_color if current_tab == 0 else edit_color

var _updating := false


func _ready() -> void:
	set_tab_title(0, tr("mapper/text.tab.create"))
	set_tab_title(1, tr("mapper/text.tab.delete"))
	set_tab_title(2, tr("mapper/text.tab.edit"))
	for field: LineEdit in [create_content, edit_content]:
		field.max_length = MapTextData.MAX_TEXT_LENGTH
	for field: SpinBox in [create_size, edit_size]:
		field.min_value = MapTextData.MIN_FONT_SIZE
		field.max_value = MapTextData.MAX_FONT_SIZE
		field.value = MapTextData.DEFAULT_FONT_SIZE
		field.get_line_edit().gui_input.connect(_size_input.bind(field))
	edit_content.text_changed.connect(func(_value: String) -> void: _settings_changed())
	edit_size.value_changed.connect(func(_value: float) -> void: _settings_changed())
	edit_color.color_changed.connect(func(_value: Color) -> void: _settings_changed())
	straighten_button.pressed.connect(func() -> void: straighten_requested.emit())
	set_selected({})


func settings() -> Dictionary:
	return {
		"text": content.text,
		"size": font_size.value,
		"color": ISUtil.from_color(color_picker.color)
	}


func set_selected(label: Dictionary) -> void:
	_updating = true
	straighten_button.disabled = label.is_empty()
	edit_content.editable = not label.is_empty()
	edit_size.editable = not label.is_empty()
	edit_color.disabled = label.is_empty()
	edit_title.text = tr(
		"mapper/text.edit.select" if label.is_empty() else "mapper/text.edit.title"
	)
	if not label.is_empty():
		edit_content.text = label["text"]
		edit_size.value = float(label["size"])
		edit_color.color = ISUtil.to_color(label["color"] as Array)
	else:
		edit_content.text = ""
	_updating = false


func _settings_changed() -> void:
	if not _updating:
		settings_changed.emit()


func _size_input(event: InputEvent, field: SpinBox) -> void:
	if event is InputEventKey and event.pressed and event.keycode in [KEY_ENTER, KEY_KP_ENTER]:
		field.apply()
		field.get_line_edit().accept_event()


func _unhandled_key_input(event: InputEvent) -> void:
	if not is_visible_in_tree():
		return
	if event.is_action_pressed("ui_tab_1"):
		current_tab = 0
	elif event.is_action_pressed("ui_tab_2"):
		current_tab = 1
	elif event.is_action_pressed("ui_tab_3"):
		current_tab = 2
