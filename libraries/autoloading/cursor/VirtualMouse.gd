class_name VirtualMouse
extends Sprite2D

enum Action { DEFAULT, BRUSH, DICE, PANNING, HAND }

const ACTION_TEX_MAP: Dictionary[Action, Texture2D] = {
	Action.DEFAULT: preload("uid://dmqeubohwubs"),
	Action.BRUSH: preload("uid://c5cl8n3npd8bn"),
	Action.DICE: preload("uid://dmqeubohwubs"),  # TODO make better dice cursor [for now we default to regular cursor]
	#Action.DICE: preload("uid://dumkbg3oyffeh"),
	Action.PANNING: preload("uid://byfqo6a6v6gvn"),
	Action.HAND: preload("uid://btcu27i6g5qag")
}

const ACTION_OFFSET_MAP: Dictionary[Action, Vector2] = {
	Action.DEFAULT: Vector2(7, 9),
	Action.BRUSH: Vector2(12, 12),
	Action.DICE: Vector2(7, 9),
	#Action.DICE: Vector2(0, 0),
	Action.PANNING: Vector2(0, 0),
	Action.HAND: Vector2(4, 13),
}

static var _instance: VirtualMouse
											
var action: Action = Action.DEFAULT
var tool_action: Action = Action.DEFAULT


func _init() -> void:
	_instance = self

func _ready() -> void:
	Input.set_custom_mouse_cursor(
		ACTION_TEX_MAP[Action.HAND],
		Input.CursorShape.CURSOR_POINTING_HAND,
		ACTION_TEX_MAP[Action.HAND].get_size()/2-ACTION_OFFSET_MAP[Action.HAND])
	set_action(Action.DEFAULT)

func set_action(new_action: Action) -> void:
	var hotspot := ACTION_TEX_MAP[new_action].get_size()/2-ACTION_OFFSET_MAP[new_action]
	Input.set_custom_mouse_cursor(ACTION_TEX_MAP[new_action], 0, hotspot)
	action = new_action


func set_action_tool(new_action: Action) -> void:
	tool_action = new_action
	var hotspot := ACTION_TEX_MAP[tool_action].get_size()/2-ACTION_OFFSET_MAP[tool_action]
	Input.set_custom_mouse_cursor(ACTION_TEX_MAP[tool_action], 0, hotspot)
	action = tool_action
