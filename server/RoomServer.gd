extends Node
class_name RoomServer

var room: Room = null
var map_controller: RoomMap = RoomMap.new()
@onready var server_controller: ServerController = get_parent()
@onready var ws_server: WSServer = get_parent().ws_server
var connected_peers := [] #peers that have finished making a connection

func get_text_data(peer_id: int) -> String:
	var peer := 0x7fffffffffffffff
	var ret: Array
	while peer != peer_id:
		ret = await ws_server.text_data
		peer = ret[0]
	return ret[1]

func parse_json(text: String) -> Result:
	var json := JSON.new()
	var error := json.parse(text)
	if error != OK:
		return Result.err(error)
	return Result.ok(json.data)

func get_json_data(peer_id: int) -> Result:
	var data := await get_text_data(peer_id)
	return parse_json(data)

func peer_player_id(peer_id: int) -> int:
	for player_id: int in room.players.keys():
		if room.players.getv(player_id).peer_id == peer_id:
			return player_id
	return -1

func _on_peer_close(peer_id: int) -> void:
	var player_id := peer_player_id(peer_id)
	room.players.erase(player_id)
	send_event("_is2_player_exit", player_id)
	if room.close_on_empty and not room.players.keys():
		server_controller.close_room(server_controller._room_find_id(self))

func peer_close(peer_id: int, code := 1000, reason := "") -> void:
	ws_server.close(peer_id, code, reason)
	server_controller.peer_rooms.erase(peer_id)
	_on_peer_close(peer_id)

func send_event(event: String, details: Variant, origin_id := -1) -> Error:
	for player_id: int in room.players.keys():
		var peer_id: int = room.players.getv(player_id).peer_id
		var error := ws_server.send_text(peer_id, JSON.stringify({"event": event, "player_id": origin_id, "details": details}))
		if error:
			return error
	return OK

func close_room() -> void:
	for player_id: int in room.players.keys():
		ws_server.close(room.players.getv(player_id).peer_id)

func _connected(peer_id: int, created: bool = false) -> void:
	if room.players.size() >= room.player_limit:
		ws_server.close(peer_id, 6144, "The room is at maximum capacity.")
		return
	if ws_server.peer_ip(peer_id) in room.banned_ips:
		ws_server.close(peer_id, 6145, "You are banned from this room.")
		return
	var player_id := room.id_iterator
	room.id_iterator += 1
	while room.id_iterator in room.players.keys():
		room.id_iterator += 1

	if created:
		ws_server.send_targeted_event(peer_id, "_is2_room_info", {"room_id": server_controller._room_find_id(self), "player_id": player_id})
	else:
		ws_server.send_targeted_event(peer_id, "_is2_room_info", {"player_id": player_id})
	if room.password:
		ws_server.send_targeted_event(peer_id, "_is2_login")
		var attempts := 1
		while attempts <= 5:
			var password_json := await get_json_data(peer_id)
			if not ISUtil.valid_event_is(password_json, "_is2_password_attempt"):
				ws_server.close(peer_id, 4096, "Protocol failurea")
				return
			if password_json["details"] == room.password:
				ws_server.send_targeted_event(peer_id, "_is2_login_valid_password")
				break
			ws_server.send_targeted_event(peer_id, "_is2_login_invalid_password", 5-attempts)
			attempts += 1
		if attempts > 5:
			ws_server.close(peer_id, 4097, "Too many password attempts")
			return
	
	ws_server.send_targeted_event(peer_id, "_is2_username")
	var username_json := await get_json_data(peer_id)
	var player: Player
	if not ISUtil.valid_event_is(username_json, "_is2_username"):
		ws_server.close(peer_id, 4096, "Protocol failureb")
		return
	else:
		player = Player.new(peer_id, {username = username_json.val()["details"], logged_in = false})
	
	if len(player.username) < 3 or len(player.username) > 20:
		ws_server.close(peer_id, 4099, "Invalid username")
		return
		
	if player.username in room.taken_usernames():
		ws_server.close(peer_id, 4100, "Username in use")
		return
		
	# CRITICAL token stuff
	
	if created:
		player.operator = true
	send_event("_is2_player_join", {"player_id": player_id, "details": {"username": player.username, "logged_in": player.logged_in, "profile": player.profile}})
	room.players.setv(player_id, player)
	ws_server.send_targeted_event(peer_id, "_is2_handshake_complete", {"name": room.name, "description": room.description, "players": room.player_info()})
	if not created:
		var serialized := room.map.serialize()
		var compressed := serialized.compress(FileAccess.COMPRESSION_FASTLZ)
		var parts := ceili(len(compressed) / 250000.0)
		var sizedata := PackedByteArray()
		sizedata.resize(4)
		sizedata.encode_u32(0, serialized.size())
		ws_server.send_targeted_binary(
			peer_id,
			ISUtil.BinaryEvents.SYNC_MAP_SIZE,
			sizedata,
			ISUtil.BinaryFlags.NONE,
			false)
				
		for part in parts:
			var last := part == parts - 1
			ws_server.send_targeted_binary(
				peer_id,
				ISUtil.BinaryEvents.SYNC_MAP_END if last else ISUtil.BinaryEvents.SYNC_MAP, # TODO move this entire thing over to actual chunk system 
				compressed.slice(part * 250000, 0xFFFFFFFF if last else (part + 1) * 250000),
				ISUtil.BinaryFlags.NONE,
				false
			)
			await get_tree().create_timer(0.1).timeout 
	# TODO: fix self.room.map.get_map_as_image().data not being EMPTY ):
	var data := []
	for v in 3:
		data.append(5)
	#self.server_controller.send_chunked_binary(peer_id, 1, 1, PackedByteArray(data))
	room.player_ids_chronological.append(player_id)
	connected_peers.append(peer_id)

func parse_event(data: Dictionary, peer_id: int) -> bool:
	if data["event"] == "map_update":
		room.map.get_map_update(data["details"])
	elif data["event"] == "ban":
		if room.players.getv(peer_player_id(peer_id)).operator:
			var ban_id: int = data["details"]
			var banned_peer: int = room.players.getv(ban_id).peer_id
			room.banned_ips.append(ws_server.peer_ip(banned_peer))
			ws_server.close(banned_peer, 5000, "Banned from this room")
			
	#return value is true if it should be broadcasted to the rest of the server
	return true

func _closed(peer_id: int, code: int, reason: String) -> void:
	_on_peer_close(peer_id)

func _text_data(peer_id: int, data: String) -> void:
	if peer_id in connected_peers:
		var data_json := parse_json(data)
		if ISUtil.valid_event(data_json):
			if parse_event(data_json.val(), peer_id):
				send_event(data_json.val()["event"], data_json.val()["details"], peer_player_id(peer_id))

func _binary_data(peer_id: int, data: Dictionary) -> void:
	pass

func _ready() -> void:
	pass
	
	## ctrl+k this to show the server map
	#var tr := TextureRect.new()
	#tr.texture = ImageTexture.create_from_image(room.map.image)
	#tr.scale = Vector2.ONE / 16
	#var timer := Timer.new()
	#timer.timeout.connect(func() -> void:
		#tr.texture.update(room.map.image)
	#)
	#add_child(timer)
	#timer.start(1)
	#add_child(tr)
