extends VBoxContainer

@onready var player_welcome: Label = $MarginContainer/HBoxContainer/Label2
@onready var player_name: Label = $MarginContainer/HBoxContainer/Name
@onready var user_list: VBoxContainer = $PanelContainer/MarginContainer/VBoxContainer/ScrollContainer/UserList
@onready var search_bar: HBoxContainer = $PanelContainer/MarginContainer/VBoxContainer/HBoxContainer

const FRIEND = preload("uid://cef5r0v705n3w")

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	if State.user:
		State.user.user_initialized.connect(_update_user)
		if State.user.initialized:
			_update_user()
			return
	player_welcome.hide()
	search_bar.get_node("Button").disabled = true
	search_bar.get_node("LineEdit").placeholder_text = "Friends coming soon :]"

func _update_user() -> void:
	player_welcome.show()
	search_bar.get_node("Button").disabled = true
	search_bar.get_node("LineEdit").placeholder_text = "Friends coming soon :]"
	player_name.text = State.user.username
	for friend: UserPartial in State.user.friends:
		var friend_node: FriendNode = FRIEND.instantiate()
		friend_node.user = friend
		user_list.add_child(friend_node)
		
