@icon("res://types/ui/PinnedScrollContainer.svg")
class_name PinnedScrollContainer
extends ScrollContainer

@export var tolerance := 5
var scroll_end := 0
var height := size.y
var go_to_bottom := false

func _ready() -> void:
	get_v_scroll_bar().changed.connect(update_scroll_if_message)
	resized.connect(_resized)
	@warning_ignore("narrowing_conversion")
	scroll_end = get_v_scroll_bar().max_value

func _resized() -> void:
	update_scroll()
	height = size.y
	
func _process(_delta: float) -> void: #bit hacky but scroll containers are insufferable to deal with
	if go_to_bottom:
		set_deferred("scroll_vertical", get_v_scroll_bar().max_value)
	if is_equal_approx(scroll_vertical, get_v_scroll_bar().max_value-get_v_scroll_bar().page):
		go_to_bottom = false

func update_scroll_if_message() -> void:
	if scroll_end != get_v_scroll_bar().max_value:
		update_scroll()
		
func update_scroll() -> void:
		var scroll_down := scroll_vertical + height >= scroll_end - tolerance
		@warning_ignore("narrowing_conversion")
		scroll_end = get_v_scroll_bar().max_value
		if scroll_down:
			go_to_bottom = true
