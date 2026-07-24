class_name RoomTemplate
extends PanelContainer

signal _readied

const ROOM_TEMPLATE = preload("uid://cfjumnaqf88s3")

var handler: RoomHandler

@export var lobby_id: String

@onready var join: Button = %Join
@onready var title: Label = %Title
@onready var description: Label = %Description
@onready var player_count: Label = %PlayerCount
@onready var friend_count: Label = %FriendCount


static func of(
	handler_: RoomHandler,
	lobby_id_: String,
	title_: String,
	desc: String,
	players: int,
	max_players: int,
	friends: Array[Player]
) -> RoomTemplate:
	var inst: RoomTemplate = ROOM_TEMPLATE.instantiate()
	inst._readied.connect(
		func() -> void:
			inst.handler = handler_
			inst.lobby_id = lobby_id_
			inst.title.text = title_
			inst.description.text = desc
			inst.player_count.text = "%d/%d" % [players, max_players]
			inst.friend_count.text = TranslationServer.translate_plural("roomlist/friend.count", "roomlist/friend.count_plural", friends.size()) 
			inst.friend_count.text %= friends.size()
			if friends.size() == 0:
				inst.friend_count.hide()
	)
	return inst


func _ready() -> void:
	_readied.emit()
	join.pressed.connect(handler.join_room.bind(lobby_id))
