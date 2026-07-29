class_name ControlPopupButton
extends Button

@export var persistence_time: float = 10.0

var _panel: PanelContainer
var _tween: Tween


func _init() -> void:
	toggle_mode = true
	toggled.connect(_toggled)


func _ready() -> void:
	_panel = PanelContainer.new()
	_panel.theme_type_variation = &"TooltipPanel"
	_panel.modulate = Color.TRANSPARENT
	_panel.z_index = z_index + 16
	var children := get_children()
	for child: Control in children:
		remove_child(child)
		child.show()
		_panel.add_child(child)
	add_child(_panel)
	_panel.hide()


func _toggled(toggled_on: bool) -> void:
	if _tween:
		_tween.kill()
	if toggled_on:
		_show_popup()
	else:
		_hide_popup()


func _show_popup() -> void:
	_panel.modulate = Color.TRANSPARENT
	_panel.show()
	_panel.position = Vector2(size.x / 2, 5) - Vector2(_panel.size.x / 2, _panel.size.y)
	_tween = create_tween().set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_QUART)
	_tween.tween_property(_panel, "position", _panel.position + Vector2(0, -10), 0.2)
	_tween.parallel().tween_property(_panel, "modulate", Color.WHITE, 0.2)
	_tween.tween_interval(persistence_time)
	_tween.tween_callback(pressed.emit)
	_tween.tween_property(self, "button_pressed", false, 0)
	_tween.tween_callback(_toggled.bind(false))


func _hide_popup() -> void:
	if _panel == null:
		return
	_tween = create_tween().set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_QUART)
	_tween.tween_property(_panel, "position", _panel.position - Vector2(0, -10), 0.2)
	_tween.parallel().tween_property(_panel, "modulate", Color.TRANSPARENT, 0.2)
	_tween.tween_callback(_panel.hide)
