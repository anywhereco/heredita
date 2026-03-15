class_name FriendNode
extends PanelContainer

const FRIEND = preload("uid://cef5r0v705n3w")

var user: UserPartial

@onready var username: Label = $MarginContainer/HBoxContainer/VBoxContainer/Username
@onready var action: Label = $MarginContainer/HBoxContainer/VBoxContainer/Action
@onready var other_actions_menu: MenuButton = $MarginContainer/HBoxContainer/OtherActionsMenu
@onready var user_join: Button = $MarginContainer/HBoxContainer/UserJoin


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	username.text = user.username
	action.text = "TODO: id = %d" % user.id
