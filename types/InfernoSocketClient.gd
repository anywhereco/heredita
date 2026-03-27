## Handles InfernoSocket connections.
class_name InfernoSocketClient
extends Node

var return_handshake := {
	"infernosocket_version": [3, 0],
	"software_version": ProjectSettings.get_setting_with_override("application/config/version")
}

var handshake_headers: PackedStringArray
var supported_protocols: PackedStringArray
var tls_options: TLSOptions = null
var websocket_url: String

var room_id: int

var ping_timer: float = 0

const PING_INTERVAL: float = 5

var socket := WebSocketPeer.new()
var last_state := WebSocketPeer.STATE_CLOSED
var player_id: int = -2  # -1 is reserved for the server, so we default to -2

var operator: bool = false

var _prompt: PromptInstance
var _prompt_instance: Node
var _attempts := 5

var room: Room
var creating_room := {}
var creating_map: PackedByteArray = PackedByteArray()

var chunk_sender: ISUtil.ChunkSender
var chunk_reciever: ISUtil.ChunkReceiver

const TIMEOUT: int = 10000  #ms
const BUFFER_SIZE_KB: int = 2048

signal connected_to_server
signal connection_closed

signal handshake_complete

signal message_received(event: String, player_id: int, details: Variant)

signal binary_message_received(event: int, player_id: int, flags: int, details: PackedByteArray)


func _init(
	url: String = "",
	_room: int = 0,
	creating: Dictionary = {},
	map: PackedByteArray = PackedByteArray()
) -> void:
	websocket_url = url
	room_id = _room
	if creating != {}:
		operator = true
	creating_room = creating
	creating_map = map
	chunk_sender = ISUtil.ChunkSender.new(func(data: PackedByteArray) -> void: socket.send(data))
	chunk_reciever = ISUtil.ChunkReceiver.new()
	chunk_reciever.chunk_received.connect(func(id: int) -> void:
		send("_is2_chunk_received", id)
	)
	chunk_reciever.chunked_message.connect(func(event: int, target: int, data: PackedByteArray) -> void:
		binary_message_received.emit(event, target, ISUtil.BinaryFlags.NONE, data)
	)


func _ready() -> void:
	socket.outbound_buffer_size = BUFFER_SIZE_KB * 1024
	socket.inbound_buffer_size = BUFFER_SIZE_KB * 1024
	var err := self.connect_to_url(websocket_url)
	if err != OK:
		print("Unable to connect")
		set_process(false)


#region Encode and Decode
func _encode_data(value: Variant) -> String:
	return JSON.stringify(value)


func _decode_data(string: String) -> Result:
	var json := JSON.new()
	var error := json.parse(string)
	if error != OK:
		return Result.err(error)
	return Result.ok(json.data)


#endregion


func connect_to_url(url: String) -> int:
	socket.supported_protocols = supported_protocols
	socket.handshake_headers = handshake_headers

	var err := socket.connect_to_url(url, tls_options)
	if err != OK:
		return err

	last_state = socket.get_ready_state()
	return OK


func send(event: String, message: Variant = null) -> int:
	var data := _encode_data(
		{
			"event": event,
			"details": message,
		}
	)
	return socket.send_text(data)


func send_binary(
	event: int, target: int, message: PackedByteArray = PackedByteArray(), compress: bool = true
) -> int:
	return socket.send(ISUtil._create_binary(event, target, message, compress))


func get_message_raw() -> Variant:
	if socket.get_available_packet_count() < 1:
		return null
	var pkt := socket.get_packet()
	if socket.was_string_packet():
		return pkt.get_string_from_utf8()
	else:
		return pkt


func close(code: int = 1000, reason: String = "") -> void:
	socket.close(code, reason)
	last_state = socket.get_ready_state()


func clear() -> void:
	socket = WebSocketPeer.new()
	last_state = socket.get_ready_state()


func get_socket() -> WebSocketPeer:
	return socket


func int_keys(dict: Dictionary) -> Dictionary[int, Variant]:
	var new_dict: Dictionary[int, Variant] = {}
	for key: Variant in dict:
		new_dict[key as int] = dict[key]
	return new_dict


func convert_players(dict: Dictionary) -> Dictionary[int, Player]:
	var new_dict: Dictionary[int, Player] = {}
	for key: Variant in dict:
		new_dict[key as int] = Player.from_info(dict[key] as Dictionary)
	return new_dict


#region Polling
func poll() -> void:
	if socket.get_ready_state() != socket.STATE_CLOSED:
		socket.poll()

	var state := socket.get_ready_state()

	if last_state != state:
		last_state = state
		if state == socket.STATE_OPEN:
			connected_to_server.emit()
		elif state == socket.STATE_CLOSED:
			connection_closed.emit()
	while socket.get_ready_state() != socket.STATE_CLOSED and socket.get_available_packet_count():
		#print("wa")
		_poll_loop()


func _poll_loop() -> void:
	var message_raw: Variant = get_message_raw()
	if message_raw is String:
		var message_res := _decode_data(message_raw as String)  # Godot, I promise you this String is a String. I swear.
		if message_res.is_err():
			return
			
		prints("CLIE recv dir", message_raw as String)
		_poll_string(message_res.val() as Dictionary)
	else:
		if message_raw == null:
			return
		_poll_binary(message_raw as PackedByteArray)


func _poll_string(message: Dictionary) -> void:
	if message == null:
		return
	#print("c<s %s" % str(message))
	if message.has("event") and message.has("player_id"):
		message["player_id"] = message["player_id"] as int
		if message["player_id"] != -1:
			message_received.emit(
				message["event"], message["player_id"], message.get("details", null)
			)
			return
		match message["event"]:
			"_is2_chunk_received":
				prints("CLIE recv", message["details"])
				chunk_sender.chunk_recieved.emit(message.get("details", 0))
			"_is2_handshake":
				print("handshake")
				if creating_room:
					chunk_sender.send(ISUtil.BinaryEvents.SYNC_MAP, -1, creating_map)
					#var map_compr := creating_map.compress(FileAccess.COMPRESSION_FASTLZ)
					#creating_room["map_file_size"] = creating_map.size()
					#send("_is2_create_room", creating_room)
					#var parts := ceili(len(map_compr) / 250000.0)
					#for part in parts:
						#var last := part == parts - 1
						#send_binary(
							#(
								#ISUtil.BinaryEvents.SYNC_MAP_END
								#if last
								#else ISUtil.BinaryEvents.SYNC_MAP
							#),  # TODO move this entire thing over to actual chunk system
							#-1,
							#map_compr.slice(
								#part * 250000, 0xFFFFFFFF if last else (part + 1) * 250000
							#),
							#false
						#)
						#await get_tree().create_timer(0.1).timeout
					#return
				send("_is2_room_info", room_id)
				return
			"_is2_room_info":
				print("room info")
				if message.get("details").has("room_id"):  #creating room
					room_id = message.get("details").get("room_id")
				player_id = message.get("details").get("player_id") as int
				#hosts = message.get("details").get("hosts")
				return
			"_is2_login":
				_prompt_instance = load("res://types/ui/PasswordPrompt.tscn").instantiate()
				(_prompt_instance.find_child("PasswordEdit") as LineEdit).text_submitted.connect(
					func password_attempt(pwd: String) -> void: send("_is2_password_attempt", pwd)
				)
				var _prompt_res := Prompts.new_fullscreen_prompt()
				if _prompt_res.is_err():
					close(1006, "Could not create login prompt, aborting")
				_prompt = _prompt.val()
				_prompt.add_child(_prompt_instance)
				return
			"_is2_login_valid_password":
				return
			"_is2_login_invalid_password":
				_attempts -= 1
				if _attempts == 0:
					_prompt.close()
					socket.close()
					return
				var attempts_label: Label = _prompt_instance.find_child("AttemptsLabel")
				attempts_label.show()
				attempts_label.text = "%d attempts remaining" % _attempts
				return
			"_is2_username":
				print("username")
				if State.user.initialized:
					send("_is2_username", State.user.username)
				else:
					send("_is2_username", State.guest_username)
				return
			"_is2_token":
				print("token")
				if State.user.initialized:
					var token_res: Variant = State.user.token
					send("_is2_token", token_res)
					return
				send("_is2_token", "")
				return
			"_is2_handshake_complete":
				print("complete")
				room = Room.new()
				State.room = room
				room.name = message.get("details").get("name")
				room.description = message.get("details").get("description")
				room.players = ReactiveDictionary.new(
					convert_players(message.get("details").get("players") as Dictionary)
				)
				handshake_complete.emit()
				return
			"_is2_player_join":
				@warning_ignore("unsafe_call_argument")
				room.players.setv(
					message.get("details").get("player_id") as int,
					Player.from_info(message.get("details").get("details"))
				)
				message_received.emit("is2_player_join", -1, message.get("details"))
				return
			"_is2_player_exit":
				room.players.erase(message.get("details"))
				message_received.emit("is2_player_exit", -1, message.get("details"))
				return
			"_is2_player_status_update":
				var player: Player = room.players.getv(
					message.get("details").get("player_id") as int
				)
				player.status = message.get("details").get("status")
				message_received.emit("is2_player_status_update", -1, message.get("details"))
				return
			"_is2_pong":
				return
			_:
				message_received.emit(
					message["event"], message["player_id"], message.get("details", null)
				)


func _poll_binary(message: PackedByteArray) -> void:
	if chunk_reciever.handle_potential_chunked_message(message):
		return
	var data := ISUtil._parse_binary(message)
	binary_message_received.emit(data.event, data.uid, data.flags, data.data)


func _process(delta: float) -> void:
	poll()
	ping_timer += delta
	if ping_timer > PING_INTERVAL and socket.get_ready_state() != socket.STATE_CLOSED:
		#print("client: socket state %s" % socket.get_ready_state())
		send("_is2_ping")
		ping_timer -= PING_INTERVAL
#endregion
