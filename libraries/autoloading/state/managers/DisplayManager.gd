class_name DisplayManager
extends Node

## If the root window was just moved or resized.
signal root_window_moved_or_resized

## The default viewport size.
const DEFAULT_VIEWPORT_SIZE: Vector2 = Vector2(720, 480)
const UI_SCALE_MULTIPLIER := 1.5

## The root window's script.
const ROOT_WINDOW_SCRIPT: Script = preload("res://libraries/autoloading/state/managers/window_notification_handling.gd")

## The root window.
@onready var root_window: Window = get_tree().root

## The display server's recommended scale.
@warning_ignore("unsafe_call_argument")
@onready
var display_server_recommended_scale: float:
	get: return DisplayServer.screen_get_scale(DisplayServer.SCREEN_OF_MAIN_WINDOW) * Settings.getv("ui_scale") * 1.5

## The true scale.
## The content scale factor is set to this.
@onready var scale := ReactiveFloat.new(_calculate_true_scale())


func _ready() -> void:
	root_window.set_script(ROOT_WINDOW_SCRIPT)
	root_window.content_scale_factor = scale.value
	Settings.get_reactive("ui_scale").value_changed.connect(
		_root_window_rescaled_or_moved.unbind(1)
	)


func _calculate_true_scale() -> float:
	var max_fit_scale_x := root_window.size.x / DEFAULT_VIEWPORT_SIZE.x
	var max_fit_scale_y := root_window.size.y / DEFAULT_VIEWPORT_SIZE.y
	var max_fit_scale := minf(max_fit_scale_x, max_fit_scale_y)
	return minf(display_server_recommended_scale, max_fit_scale)


func _root_window_notifications(notif: int) -> void:
	match notif:
		NOTIFICATION_WM_POSITION_CHANGED, NOTIFICATION_WM_SIZE_CHANGED:
			_root_window_rescaled_or_moved()


func _root_window_rescaled_or_moved() -> void:
	var prev_scale := scale.value
	scale.value = _calculate_true_scale()
	if prev_scale != scale.value:
		root_window.content_scale_factor = scale.value
	root_window_moved_or_resized.emit()
