class_name TextDisplayButton
extends ControlPopupButton

@export var text_to_show: String = ""

var _label: Label


func _ready() -> void:
	_label = Label.new()
	_label.theme_type_variation = &"TooltipLabel"
	_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	add_child(_label)
	super._ready()


func _show_popup() -> void:
	if _label:
		_label.text = tr(text_to_show)
	super._show_popup()
