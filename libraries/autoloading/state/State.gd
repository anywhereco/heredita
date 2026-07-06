## The game state singleton.
extends Node

var glass_ui: ShaderMaterial = preload("uid://dayrr5lupf1h2")
var prompt_blur: ShaderMaterial = preload("uid://csqrvtuylh0sx")

var refocus_debounce := 0.0

@onready var display := DisplayManager.new()

@onready var brush_shape_map := BrushShapeMap.new()

var client: InfernoSocketClientTemp = null
var room: Room = null

## Should not be null. Make sure to check if the user is logged in via State.user.initialized.
var user: PrimaryUser = null

var player: Player:
	get:
		return room.players.getv(client.player_id) if room else null

var guest_username := ""

var _http_requesting_node_for_user: HTTPRequest

var refocus_callback: JavaScriptObject

func _ready() -> void:
	if OS.get_name() == "Web":
		refocus_callback = JavaScriptBridge.create_callback(_refocus_callback)
		var window := JavaScriptBridge.get_interface("window")
		window.addEventListener("focus", refocus_callback)

	Statics.initialize()
	
	Settings.get_reactive("enable_blurred_ui").value_changed.connect(blurred_ui_handler)
	@warning_ignore("unsafe_call_argument")
	blurred_ui_handler(Settings.get_reactive("enable_blurred_ui"))
	
	add_child(display)
	display.name = "DisplayManager"
	_http_requesting_node_for_user = HTTPRequest.new()
	add_child(_http_requesting_node_for_user)

	reset_user()


func _logout() -> void:
	var tokenfile := FileAccess.open("user://DO_NOT_SHARE-token.txt", FileAccess.WRITE)
	tokenfile.store_string("")
	user.token = ""
	user.initialize()


func reset_user() -> void:
	var token := FileAccess.get_file_as_string("user://DO_NOT_SHARE-token.txt")
	user = PrimaryUser.new(_http_requesting_node_for_user)
	user.user_initialized.connect(
		func() -> void:
			var tokenfile := FileAccess.open("user://DO_NOT_SHARE-token.txt", FileAccess.WRITE)
			tokenfile.store_string(user.token)
	)
	if token != "":
		user.token = token
		user.initialize()


## This function should be called if a user has just logged in and needs to be given an HTTPRequest node.
func ready_user() -> void:
	user.http = _http_requesting_node_for_user


func blurred_ui_handler(reactive: ReactiveBool) -> void: 
	glass_ui.set_shader_parameter("enable_blur", reactive.value)
	prompt_blur.set_shader_parameter("enable_blur", reactive.value)
  
func _process(delta: float) -> void:
	refocus_debounce -= delta
	

func _refocus_callback(_args: Array) -> void:
	if refocus_debounce > 0:
		return
	refocus_debounce = 60
	if Map._instance:
		Map._instance.resync()
