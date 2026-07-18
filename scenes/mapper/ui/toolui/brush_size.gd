class_name BrushSizeController
extends VBoxContainer

const DEBOUNCE_START := 0.500
const DEBOUNCE_MAX_RESET := 0.350
const DEBOUNCE_MIN_RESET := 0.075

@onready var size_label: Label = $"../Size"
@onready var h_slider: HSlider = $HSlider

var brush_size: ReactiveInt = ReactiveInt.new(1)

var size_modify_debounce := -1.0
var held_size_change_count := 0

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass  # Replace with function body.


func _process(delta: float) -> void:
	_size_modify_check(delta)


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


func _size_modify_check(delta: float) -> void:
	if Input.is_action_just_pressed("brush_increase") or Input.is_action_just_pressed("brush_decrease") and size_modify_debounce == -1:
		size_modify_debounce = DEBOUNCE_START
	if (Input.is_action_just_released("brush_increase") or Input.is_action_just_released("brush_decrease"))\
	   and not (Input.is_action_pressed("brush_increase") or Input.is_action_pressed("brush_decrease")):
		size_modify_debounce = -1
		held_size_change_count = 0
	if Input.is_action_pressed("brush_increase") or Input.is_action_pressed("brush_decrease"):
		size_modify_debounce -= delta
		var direction := 1 if Input.is_action_pressed("brush_increase") else -1 
		while size_modify_debounce <= 0:
			held_size_change_count += 1
			size_modify_debounce += maxf(DEBOUNCE_MIN_RESET, (
				DEBOUNCE_MAX_RESET / ((held_size_change_count + 2) * 0.5)
			))
			h_slider.value += direction
