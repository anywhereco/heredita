class_name MainMenuForeground
extends CanvasLayer

@onready var switch_element: Control = $SwitchElement
static var _instance: MainMenuForeground

enum Page {
	LANDING,
	ROOM_LIST,
	GALLERY,
	MPTEST
}

var page: Page = Page.LANDING

# pages
const LANDING = preload("uid://crasgtic6vnmh")
const ROOM_LIST = preload("uid://cww8q0kd7eghb")
const GALLERY = preload("uid://c1fcr11flbild")
const MPTEST = preload("uid://dehpp1j2c2t4a")

func _init() -> void:
	_instance = self

func _ready() -> void:
	Prompts.override_ui = self
	if "--server" in OS.get_cmdline_user_args():
		get_tree().change_scene_to_file.call_deferred("res://server/Server.tscn")
		CursorLayer.queue_free()
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE

func swap_page(new_page: Page) -> void:
	var inst: Node
	match new_page:
		Page.LANDING:
			inst = LANDING.instantiate()
		Page.ROOM_LIST:
			inst = ROOM_LIST.instantiate()
		Page.GALLERY:
			inst = GALLERY.instantiate()
		Page.MPTEST:
			inst = MPTEST.instantiate()
	switch_element.add_child(inst)
	switch_element.get_child(0).queue_free()
	switch_element.get_child(0).hide()
