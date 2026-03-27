extends Node
class_name ServerController

const TIMEOUT: int = 10000  #ms

var rooms: Dictionary[int, RoomServer]
var peer_rooms: Dictionary[int, int]
var ws_server := WSServer.new()

var bridge: Server2ServerBridge


func _ready() -> void:
	bridge = Server2ServerBridge.new(self)
	add_child(bridge)
	add_child(ws_server)
	ws_server.text_data.connect(_text_data)
	ws_server.binary_message.connect(_binary_message)
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
	room.map = MapData.deserialize(map_data)
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
		if not ret:  #timed out
			return ""
		peer = ret[0]
	return ret[1]


func parse_binary(data: PackedByteArray) -> Dictionary:
	var event := ISUtil._parse_binary(data)
	return {"event": event.event, "target": event.uid, "data": event.data}


func get_binary_data(peer_id: int) -> Dictionary:
	var peer := 0x7fffffffffffffff
	var ret: Array
	while peer != peer_id:
		var timer := get_tree().create_timer(TIMEOUT)
		ret = await TimedPromise.new(timer, ws_server.binary_data).done
		if not ret:  #timed out
			return {}
		peer = ret[0]
	var data: PackedByteArray = ret[1]
	return parse_binary(data)


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
		@warning_ignore("unsafe_call_argument")
		var rid := int(json.val()["details"])
		if not rooms.has(rid):
			ws_server.close(peer_id, 6146, "Room does not exist")
			return
		peer_rooms[peer_id] = rid
		var r := rooms[rid]
		r._connected(peer_id)
		return
	elif ISUtil.valid_event_is(json, "_is2_create_room"):
		var size: int = json.val()["details"]["map_file_size"]
		var map_content: PackedByteArray = PackedByteArray([])
		while true:
			var map_data: Dictionary = await get_binary_data(peer_id)
			var map_data_body: PackedByteArray = map_data["data"]
			map_content.append_array(map_data_body)
			if map_data["event"] == ISUtil.BinaryEvents.SYNC_MAP_END:
				break
		@warning_ignore("unsafe_call_argument")
		var rid := create_room(
			json.val()["details"], map_content.decompress(size, FileAccess.COMPRESSION_FASTLZ)
		)
		peer_rooms[peer_id] = rid
		var r := rooms[rid]
		r._connected(peer_id, true)
		return
	ws_server.close(peer_id, 4096, "Protocol failuree")


func _text_data(peer_id: int, data: String) -> void:
	if peer_id in peer_rooms:
		rooms[peer_rooms[peer_id]]._text_data(peer_id, data)
	else:
		var data_json := parse_json(data)
		if not (
			ISUtil.valid_event_is(data_json, "_is2_room_info")
			or ISUtil.valid_event_is(data_json, "_is2_create_room")
		):
			ws_server.close(peer_id, 4096, "Protocol failured")


func _binary_message(peer_id: int, event: int, player_id: int, flags: int, details: PackedByteArray) -> void:
	if peer_id in peer_rooms:
		rooms[peer_rooms[peer_id]]._binary_data(peer_id, event, player_id, flags, details)
	else:
		if not data_parsed["event"] in ISUtil.BinaryEvents.values():  # == ISUtil.BinaryEvents.SYNC_MAP: # TODO probably needs to be only the map events
			ws_server.close(peer_id, 4096, "Protocol failurec")


func _closed(peer_id: int, code: int, reason: String) -> void:
	if peer_id in peer_rooms:
		rooms[peer_rooms[peer_id]]._closed(peer_id, code, reason)
		peer_rooms.erase(peer_id)
