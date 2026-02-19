## Handles InfernoSocket v2 connections.
class_name InfernoSocketClient
extends Node

var return_handshake := {
	"infernosocket_version" = [2, 1],
	"software_version" = ProjectSettings.get_setting_with_override("application/config/version") 
}

var handshake_headers: PackedStringArray
var supported_protocols: PackedStringArray
var tls_options: TLSOptions = null
var websocket_url: String

var room_id: int

var ping_timer: float = 0

const PING_INTERVAL: float = 60

var socket := WebSocketPeer.new()
var last_state := WebSocketPeer.STATE_CLOSED
var player_id: int = -2 # -1 is reserved for the server, so we default to -2
var hosts := []

var _prompt: PromptInstance
var _prompt_instance: Node
var _attempts := 5

var room: Room
var creating_room := {}
var creating_map: PackedByteArray = PackedByteArray()

const TIMEOUT: int = 10000 #ms
const BUFFER_SIZE_KB: int = 2048

signal connected_to_server()
signal connection_closed()

signal handshake_complete()

signal message_received(event: String, player_id: int, details: Variant)

signal binary_message_received(event: int, player_id: int, flags: int, details: PackedByteArray)

## Same as [code]message_recieved[/code], but shows handshake events and is not parsed.
signal raw_message_received(string: String)

signal raw_message_sent(string: String)

func _init(url: String = "", _room: int = 0, creating: Dictionary = {}, map: PackedByteArray = PackedByteArray()) -> void:
	websocket_url = url
	room_id = _room
	creating_room = creating
	creating_map = map

func _ready() -> void:
	socket.outbound_buffer_size = BUFFER_SIZE_KB * 1024
	socket.inbound_buffer_size = BUFFER_SIZE_KB * 1024
	var err := self.connect_to_url(websocket_url)
	if err != OK:
		print("Unable to connect")
		set_process(false)
	raw_message_received.connect(self.handle_chunked_binary_events)

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
	var data := _encode_data({
		"event": event,
		"details": message,
	})
	raw_message_sent.emit(data)
	return socket.send_text(data)

func send_binary(event: int, target: int, flags: int, message: PackedByteArray = PackedByteArray(), compress: bool = true) -> int:
	assert(event >= 0 and event <= 65535, "The event value should fit within a 16-bit int")
	assert(target >= -32768 and target <= 32767, "The target value should fit within a 16-bit signed int")
	raw_message_sent.emit("<Binary event %d>" % event)
	var compression_size: int
	if compress:
		flags |= ISUtil.BinaryFlags.COMPRESSED
		compression_size = len(message)
		message = message.compress(FileAccess.COMPRESSION_FASTLZ)
	var bytes := PackedByteArray()
	bytes.resize(5)
	bytes.encode_u16(0, event)
	bytes.encode_s16(2, target)
	bytes.encode_u8(4, flags)
	if compress:
		bytes.resize(9)
		bytes.encode_u32(5, compression_size)
	bytes.append_array(message)
	return socket.send(bytes)

func send_chunked_binary(event: int, target: int, data: PackedByteArray) -> void:
	#Compression is built into this method. If it's this big we're compressing it
	var compression_size := len(data)
	assert(compression_size < 0xFFFFFFFF, "Why are you sending a 4 GB file")
	data = data.compress(FileAccess.COMPRESSION_FASTLZ)
	var chunk_count := ceili(data.size() / float(0x10000))
	var flags := ISUtil.BinaryFlags.NONE
	for i in chunk_count:
		if i == 0:
			flags |= ISUtil.BinaryFlags.BEGIN_CHUNK
		var chunk := data.slice(i*0x10000,(i+1)*0x10000)
		var bytes := PackedByteArray()
		bytes.resize(1)
		bytes.encode_u8(0, chunk_count)
		bytes.append_array(chunk)
		if i == chunk_count-1:
			flags &= ISUtil.BinaryFlags.LAST_CHUNK
		send_binary(event, target, flags, bytes, false)
		
func handle_chunked_binary_events(string: String) -> void:
	if string.begins_with("<Chunked binary event incoming>"):
		var data := await get_chunked_binary_data()
		if data.event == 1: # map event
			print("Updating maps with %s" % data.array)
			pass # update map
		

#region Receiving Chunked Binary

class ChunkedBinaryData:
	var array: PackedByteArray
	var event: int
	
	func _init(array: PackedByteArray, event: int) -> void:
		self.array = array
		self.event = event

func get_chunked_binary_data() -> ChunkedBinaryData:
	var data := []
	var data_length := 0
	var chunks_recieved := 0
	var event := 0
	var target := 0
	while true:
		var sig_data: Variant = await self.binary_message_received
		target = sig_data[1]
		var flags: int = sig_data[2]
		var chunk: PackedByteArray = sig_data[3]
		if not chunk:
			return ChunkedBinaryData.new(PackedByteArray([]), event)
		var last_flag := flags & ISUtil.BinaryFlags.LAST_CHUNK
		data_length = chunk.decode_u8(0)
		data.append_array(chunk.slice(1))
		chunks_recieved += 1
		var end_hint := int(chunks_recieved >= data_length) + int(last_flag != 0)
		if end_hint == 1:
			break
		elif end_hint == 2:
			return ChunkedBinaryData.new(PackedByteArray([]), event)
	return ChunkedBinaryData.new(data, event)
#endregion

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
	while socket.get_ready_state() == socket.STATE_OPEN and socket.get_available_packet_count():
		_poll_loop()

func _poll_loop() -> void:
	var message_raw: Variant = get_message_raw()
	if message_raw is String:
		raw_message_received.emit(message_raw)
		var message_res := _decode_data(message_raw as String) # Godot, I promise you this String is a String. I swear.
		if message_res.is_err():
			return
		_poll_string(message_res.val() as Dictionary)
	else:
		if message_raw == null:
			return
		_poll_binary(message_raw as PackedByteArray)

func _poll_string(message: Dictionary) -> void:
	if message == null:
		return
	if message.has("event") and message.has("player_id"):
		message["player_id"] = message["player_id"] as int
		if message["player_id"] != -1:
			message_received.emit(message["event"], message["player_id"], message.get("details", null))
			return
		match message["event"]:
			"_is2_handshake":
				if creating_room:
					send("_is2_create_room", creating_room)
					#send_chunked_binary(BinaryEvents.SYNC_MAP, -1, creating_map)
					send_binary(ISUtil.BinaryEvents.SYNC_MAP, -1, ISUtil.BinaryFlags.COMPRESSED, creating_map)
					return
				send("_is2_room_info", room_id)
				return
			"_is2_room_info":
				if message.get("details").has("room_id"): #creating room
					room_id = message.get("details").get("room_id")
				player_id = message.get("details").get("player_id") as int
				hosts = message.get("details").get("hosts")
				return
			"_is2_login":
				_prompt_instance = load("res://types/ui/PasswordPrompt.tscn").instantiate()
				(_prompt_instance.find_child("PasswordEdit") as LineEdit).text_submitted.connect(
					func password_attempt(pwd: String) -> void:
						send("_is2_password_attempt", pwd)
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
				#send("_is2_username", State.player.name)
				send("_is2_username", "User%d" % player_id)
				return
			"_is2_token":
				#var token_res: Variant = LocalStorage.get_item("token")
				#if token_res.is_err() or not State.user.is_account:
				#	send("_is2_token", "")
				#send("_is2_token", token_res.val())
				return
			"_is2_handshake_complete":
				room = Room.new()
				State.room = room
				room.name = message.get("details").get("name")
				room.description = message.get("details").get("description")
				room.players = ReactiveDictionary.new(int_keys(message.get("details").get("players") as Dictionary))
				handshake_complete.emit()
				return
			"_is2_player_join":
				room.players.setv(message.get("details").get("player_id") as int, message.get("details").get("details"))
				message_received.emit("is2_player_join", -1, message.get("details"))
				return
			"_is2_player_exit":
				room.players.erase(message.get("details"))
				message_received.emit("is2_player_exit", -1, message.get("details"))
				return
			"_is2_pong":
				return
			_:
				message_received.emit(message["event"], message["player_id"], message.get("details", null))

func _poll_binary(message: PackedByteArray) -> void:
	var event := message.decode_u16(0)
	var uid := message.decode_s16(2)
	var flags := message.decode_u8(4)
	var compressed := flags & ISUtil.BinaryFlags.COMPRESSED
	var data := message.slice(9 if compressed else 5)
	if compressed:
		var compression_size := message.decode_u32(5)
		data = data.decompress(compression_size, FileAccess.COMPRESSION_FASTLZ)
	print("received event %d!!" % event)

	raw_message_received.emit("<Binary event %d, \"playerid\"=%d>" % [event, uid])
	binary_message_received.emit(event, uid, flags, data)

func _process(delta: float) -> void:
	poll()
	ping_timer += delta
	if ping_timer > PING_INTERVAL and socket.get_ready_state() != socket.STATE_CLOSED:
		send("_is2_ping")
		ping_timer -= PING_INTERVAL
#endregion
