@icon("res://types/ui/PinnedScrollContainer.svg")
class_name PinnedScrollContainer
extends ScrollContainer

@export var tolerance := 5
var scroll_end := 0


func _ready() -> void:
	get_v_scroll_bar().changed.connect(update_scroll)
	@warning_ignore("narrowing_conversion")
	scroll_end = get_v_scroll_bar().max_value


func update_scroll() -> void:
	if scroll_end != get_v_scroll_bar().max_value:
		var scroll_down := scroll_vertical + size.y >= scroll_end - tolerance
		@warning_ignore("narrowing_conversion")
		scroll_end = get_v_scroll_bar().max_value
		if scroll_down:
			scroll_vertical = scroll_end
