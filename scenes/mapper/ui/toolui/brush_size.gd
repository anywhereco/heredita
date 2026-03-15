class_name BrushSizeController
extends VBoxContainer

@onready var size_label: Label = $"../Size"
@onready var h_slider: HSlider = $HSlider

var brush_size: ReactiveInt = ReactiveInt.new(1)


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass  # Replace with function body.


func _on_slider_changed(value: float) -> void:
	brush_size.value = value as int
	size_label.text = str(brush_size.value)


func _unhandled_key_input(event: InputEvent) -> void:
	if MapperRoot._instance.tool.value != MapperRoot.Tool.BRUSH:
		return

	if event.is_action_pressed("brush_increase"):
		h_slider.value += 1
	if event.is_action_pressed("brush_decrease"):
		h_slider.value -= 1
