extends EditorContextMenuPlugin

const ICON = preload("../Reactive.svg")

const UI = preload("ReactiveCreateInterface.tscn")

const CreateString = preload("uid://dofa5ia2symqv")

var ui: Window


func _popup_menu(paths):
	add_context_menu_item("Reactive...", _show_ui, ICON)


func _show_ui(arr: Array):
	ui = UI.instantiate()
	ui.theme = EditorInterface.get_editor_theme()
	var panel := ui.get_node("%Panel") as Panel
	(ui.get_node("%Wrapping") as LineEdit).text_changed.connect(_update_class_name)
	(panel.get_theme_stylebox("panel") as StyleBoxFlat).bg_color = panel.get_theme_color("base_color", "Editor")
	ui.close_requested.connect(_cleanup)
	EditorInterface.popup_dialog_centered(ui, Vector2i(350, 150))
	var btn := ui.get_node("%Create") as Button
	btn.pressed.connect(_create.bind(arr[0]))


func _write(path: String, content: String) -> void:
	var file = FileAccess.open(path, FileAccess.WRITE)
	file.store_string(content)


func _update_class_name(text: String) -> void:
	(ui.get_node("%ClassName") as LineEdit).text = "Reactive" + text

func _create(base_path: String) -> void:
	var classname := (ui.get_node("%ClassName") as LineEdit).text
	if classname.ends_with(".gd"):
		classname = classname.left(classname.length() - 3)
	var wrapping_class := (ui.get_node("%Wrapping") as LineEdit).text
	var script := CreateString.create(classname, wrapping_class)
	var path := base_path + classname.to_pascal_case() + ".gd"
	_write(path, script)
	EditorInterface.edit_resource(load(path))
	EditorInterface.get_resource_filesystem().scan()
	_cleanup()


func _cleanup() -> void:
	if ui != null:
		ui.queue_free()
		ui = null
