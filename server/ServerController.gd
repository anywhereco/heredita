extends Node
class_name ServerController

const TIMEOUT: int = 10000 #ms

var rooms: Dictionary[int, RoomServer]
var peer_rooms: Dictionary[int, int]
var ws_server := WSServer.new()

var bridge: Server2ServerBridge

func _ready() -> void:
	bridge = Server2ServerBridge.new(self)
	add_child(bridge)
	add_child(ws_server)
	ws_server.text_data.connect(_text_data)
	ws_server.binary_data.connect(_binary_data)
	ws_server.connected.connect(_connected)
	ws_server.closed.connect(_closed)

func new_room_id() -> int:
	var id := randi()
	while id in rooms:
		id = randi()
	return id

func create_room(data: Dictionary = {}, map_data: PackedByteArray = PackedByteArray()) -> int:
	var id := new_room_id()
	var room := Room.new()
	room.map = Map.new()
	room.map.deserialize(map_data)
	for key: String in data:
		if key == "name":
			room.name = data[key]
		if key == "description":
			room.description = data[key]
		if key == "password":
			room.password = data[key]
		if key == "player_cap":
			room.player_limit = data[key]
	var room_server := RoomServer.new()
	room_server.room = room
	rooms[id] = room_server
	add_child(room_server)
	return id
	
func close_room(id: int) -> void:
	rooms[id].close_room()
	rooms.erase(id)

func _room_find_id(room: RoomServer) -> int:
	return rooms.find_key(room)

func get_text_data(peer_id: int) -> String:
	var peer := 0x7fffffffffffffff
	var ret: Array
	while peer != peer_id:
		var timer := get_tree().create_timer(TIMEOUT)
		ret = await TimedPromise.new(timer, ws_server.text_data).done
		if not ret: #timed out
			return ""
		peer = ret[0]
	return ret[1]
	
func get_binary_data(peer_id: int) -> PackedByteArray:
	var peer := 0x7fffffffffffffff
	var ret: Array
	while peer != peer_id:
		var timer := get_tree().create_timer(TIMEOUT)
		ret = await TimedPromise.new(timer, ws_server.binary_data).done
		if not ret: #timed out
			return PackedByteArray([])
	return ret[1]
	
func get_chunked_binary_data(peer_id: int) -> PackedByteArray:
	var data := []
	var data_length := 0
	var chunks_recieved := 0
	var event := -1
	var target := -2
	while true:
		var chunk := await get_binary_data(peer_id)
		if not chunk:
			return PackedByteArray([])
		if event > -1 and chunk.decode_u16(0) != event:
			continue
		elif event == -1:
			event = chunk.decode_u16(0)
		if target > -2 and chunk.decode_s16(2) != target:
			continue
		elif event == -2:
			target = chunk.decode_s16(2)
		var last_flag := chunk.decode_u8(4) & InfernoSocketClient.BinaryFlags.LAST_CHUNK
		data_length = chunk.decode_u8(5)
		data.append(chunk.slice(1))
		chunks_recieved += 1
		var end_hint := int(chunks_recieved >= data_length) + int(last_flag != 0)
		if end_hint == 1: #end signal mismatch
			return PackedByteArray([])
		elif end_hint == 2:
			break
	return data

func send_binary(peer: int, event: int, target: int, flags: int, message: PackedByteArray = PackedByteArray(), compress: bool = true) -> void:
	assert(event >= 0 and event <= 65535, "The event value should fit within a 16-bit int")
	assert(target >= -32768 and target <= 32767, "The target value should fit within a 16-bit signed int")
	
	var compression_size: int
	if compress:
		flags &= InfernoSocketClient.BinaryFlags.COMPRESSED
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
	var r := self.ws_server.send_raw_binary(peer, bytes)

func send_chunked_binary(peer: int, event: int, target: int, data: PackedByteArray) -> void:
	#Compression is built into this method. If it's this big we're compressing it
	# actually lets not
	
	self.ws_server.send_text(peer, "<Chunked binary event incoming>")
	var compression_size := len(data)
	assert(compression_size < 0xFFFFFFFF, "Why are you sending a 4 GB file")
		
	var chunk_count := ceili(compression_size / float(0x1000))
	var flags := InfernoSocketClient.BinaryFlags.NONE
	for i in chunk_count:
		if i == 0:
			flags &= InfernoSocketClient.BinaryFlags.BEGIN_CHUNK
		var chunk := data.slice(i*0x1000,(i+1)*0x1000)
		var bytes := PackedByteArray()
		bytes.resize(1)
		bytes.encode_u8(0, chunk_count)
		bytes.append_array(chunk)
		if i == (chunk_count - 1):
			flags &= InfernoSocketClient.BinaryFlags.LAST_CHUNK
		send_binary(peer, event, target, flags, bytes, false)

func parse_json(text: String) -> Result:
	var json := JSON.new()
	var error := json.parse(text)
	if error != OK:
		return Result.err(error)
	return Result.ok(json.data)

func get_json_data(peer_id: int) -> Result:
	var data := await get_text_data(peer_id)
	return parse_json(data)

func _connected(peer_id: int) -> void:
	ws_server.send_targeted_event(peer_id, "_is2_handshake")
	var json := await get_json_data(peer_id)
	if ISUtil.valid_event_is(json, "_is2_room_info"):
		var rid := int(json.val()["details"])
		if not rooms.has(rid):
			ws_server.close(peer_id, 6146, "Room does not exist")
			return
		peer_rooms[peer_id] = rid
		var r := rooms[rid]
		r._connected(peer_id)
		return
	elif ISUtil.valid_event_is(json, "_is2_create_room"):
		var map_data: PackedByteArray = PackedByteArray()
		map_data = await get_chunked_binary_data(peer_id)
		var rid := create_room(json.val()["details"], map_data)
		peer_rooms[peer_id] = rid
		var r := rooms[rid]
		r._connected(peer_id, true)
		return
	ws_server.close(peer_id, 4096, "Protocol failure")

func _text_data(peer_id: int, data: String) -> void:
	if peer_id in peer_rooms:
		rooms[peer_rooms[peer_id]]._text_data(peer_id, data)
	else:
		var data_json := parse_json(data)
		if not (ISUtil.valid_event_is(data_json, "_is2_room_info") or ISUtil.valid_event_is(data_json, "_is2_create_room")):
			ws_server.close(peer_id, 4096, "Protocol failure")

func _binary_data(peer_id: int, data: PackedByteArray) -> void:
	if peer_id in peer_rooms:
		rooms[peer_rooms[peer_id]]._binary_data(peer_id, data)
	else:
		ws_server.close(peer_id, 4096, "Protocol failure")

func _closed(peer_id: int, code: int, reason: String) -> void:
	if peer_id in peer_rooms:
		rooms[peer_rooms[peer_id]]._closed(peer_id, code, reason)
		peer_rooms.erase(peer_id)
