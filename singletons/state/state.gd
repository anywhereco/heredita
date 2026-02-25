## The game state singleton.
extends Node

@onready var display := DisplayManager.new()

@onready var threading := ThreadingManager.new()

@onready var brush_shape_map := BrushShapeMap.new()

var client: InfernoSocketClient = null
var room: Room = null


## Should not be null. Make sure to check if the user is logged in via State.user.initialized.
var user: PrimaryUser = null
var player: Dictionary:
	get: return room.players.getv(client.player_id) if room else null

var guest_username := ""

var _http_requesting_node_for_user: HTTPRequest

func _ready() -> void:
	Statics.initialize()
	
	add_child(display)
	display.name = "DisplayManager"
	_http_requesting_node_for_user = HTTPRequest.new()
	add_child(_http_requesting_node_for_user)
	
	var token := FileAccess.get_file_as_string("user://DO_NOT_SHARE-token.txt") 
	user = PrimaryUser.new(_http_requesting_node_for_user)
	user.user_initialized.connect(func() -> void:
		var tokenfile := FileAccess.open("user://DO_NOT_SHARE-token.txt", FileAccess.WRITE) 
		tokenfile.store_string(user.token)
	)
	if token != "":
		user.token = token
		user.initialize()

## This function should be called if a user has just logged in and needs to be given an HTTPRequest node.
func ready_user() -> void:
	user.http = _http_requesting_node_for_user
