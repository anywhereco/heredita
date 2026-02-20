## The game state singleton.
extends Node

@onready var display := DisplayManager.new()

@onready var threading := ThreadingManager.new()

var client: InfernoSocketClient = null
var room: Room = null

## Should not be null. Make sure to check if the user is logged in via State.user.initialized.
var user: PrimaryUser = null

var _http_requesting_node_for_user: HTTPRequest

func _ready() -> void:
	Statics.initialize()
	
	add_child(display)
	display.name = "DisplayManager"
	_http_requesting_node_for_user = HTTPRequest.new()
	add_child(_http_requesting_node_for_user)
	
	var token := FileAccess.get_file_as_string("user://DO_NOT_SHARE-token.txt") 
	if token != "":
		user = PrimaryUser.new(_http_requesting_node_for_user, token)
		user.initialize()
	else:
		user = PrimaryUser.new(_http_requesting_node_for_user)

## This function should be called if a user has just logged in and needs to be given an HTTPRequest node.
func ready_user() -> void:
	user.http = _http_requesting_node_for_user
