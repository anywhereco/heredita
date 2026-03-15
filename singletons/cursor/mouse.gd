class_name VirtualMouse
extends Sprite2D

enum Action { DEFAULT, BRUSH, DICE, PANNING }

const ACTION_TEX_MAP: Dictionary[Action, Texture2D] = {
	Action.DEFAULT: preload("uid://dmqeubohwubs"),
	Action.BRUSH: preload("uid://c5cl8n3npd8bn"),
	Action.DICE: preload("uid://dmqeubohwubs"),  # TODO make better dice cursor [for now we default to regular cursor]
	#Action.DICE: preload("uid://dumkbg3oyffeh"),
	Action.PANNING: preload("uid://byfqo6a6v6gvn")
}

const ACTION_OFFSET_MAP: Dictionary[Action, Vector2] = {
	Action.DEFAULT: Vector2(7, 9),
	Action.BRUSH: Vector2(12, 12),
	Action.DICE: Vector2(7, 9),
	#Action.DICE: Vector2(0, 0),
	Action.PANNING: Vector2(0, 0)
}

const VIRTUAL_MOUSE_DEVICE := 7

static var _instance: VirtualMouse
var enabled: bool:
	set(en):
		enabled = en
		if en:
			unhide_mouse()
		else:
			hide_mouse()

var action: Action = Action.DEFAULT
var tool_action: Action = Action.DEFAULT


func _init() -> void:
	_instance = self


func set_action(new_action: Action) -> void:
	texture = ACTION_TEX_MAP[new_action]
	offset = ACTION_OFFSET_MAP[new_action]
	action = new_action


func set_action_tool(new_action: Action) -> void:
	tool_action = new_action
	texture = ACTION_TEX_MAP[tool_action]
	offset = ACTION_OFFSET_MAP[tool_action]
	action = tool_action


func _ready() -> void:
	position = get_local_mouse_position()
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)


func _process(_delta: float) -> void:
	if get_parent().get_index() != get_window().get_child_count() - 1:
		get_window().move_child.call_deferred(get_parent(), -1)
	if Input.mouse_mode != Input.MOUSE_MODE_CAPTURED and visible:
		hide()
	elif Input.mouse_mode == Input.MOUSE_MODE_CAPTURED and not visible:
		show()


func hide_mouse() -> void:
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
	hide()
	get_window().warp_mouse(position)


func unhide_mouse() -> void:
	global_position = get_global_mouse_position()
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	show()
	var rect: Rect2 = get_viewport().get_visible_rect()
	if (
		position.x < rect.position.x
		or rect.position.x > rect.end.x
		or position.y < rect.position.y
		or rect.position.y > rect.end.y
	):
		position = rect.size / 2


func _input(event: InputEvent) -> void:
	if Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
		if event is InputEventMouse and event.device != VIRTUAL_MOUSE_DEVICE:
			if event is InputEventMouseMotion and action != Action.PANNING:
				position = position + event.relative * Settings.getv("mouse_sensitivity")
				if not get_viewport().get_visible_rect().has_point(global_position):
					var rect: Rect2 = get_viewport().get_visible_rect()
					position = Vector2(
						clampf(position.x, rect.position.x, rect.end.x),
						clampf(position.y, rect.position.y, rect.end.y)
					)
				var virtual_event: InputEventMouseMotion = InputEventMouseMotion.new()
				virtual_event.relative = event.relative * Settings.getv("mouse_sensitivity")
				virtual_event.position = get_viewport().get_screen_transform() * position
				virtual_event.button_mask = event.button_mask
				virtual_event.device = VIRTUAL_MOUSE_DEVICE
				get_viewport().set_input_as_handled()
				Input.parse_input_event(virtual_event)
			elif event is InputEventMouseButton:
				var virtual_event: InputEventMouseButton = InputEventMouseButton.new()
				virtual_event.position = get_viewport().get_screen_transform() * position
				virtual_event.button_index = event.button_index
				virtual_event.pressed = event.pressed
				virtual_event.button_mask = event.button_mask
				virtual_event.device = VIRTUAL_MOUSE_DEVICE
				get_viewport().set_input_as_handled()
				Input.parse_input_event(virtual_event)
		elif event.is_action_pressed("escape_cursor_lock"):
			hide_mouse()

	else:
		if event is InputEventMouseButton and event.pressed and enabled:
			unhide_mouse()


func _notification(what: int) -> void:
	match what:
		MainLoop.NOTIFICATION_APPLICATION_FOCUS_IN:
			if OS.get_name() == "macOS":
				unhide_mouse()
