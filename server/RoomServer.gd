extends Node
class_name RoomServer

const TIMEOUT: int = 10000  #ms
const NOT_VALID_PLAYER_ID = -3

var rid: int = -1

var room: Room = null
@onready var server_controller: ServerController = get_parent()
@onready var ws_server: WSServer = get_parent().ws_server
var connected_peers := []  #peers that have finished making a connection

var tasks: Array[Task] = []


func get_text_data(peer_id: int) -> Dictionary:
	var peer := 0x7fffffffffffffff
	var ret: Array
	while peer != peer_id:
		ret = await ws_server.text_data
		peer = ret[0]
	return ret[1]

func get_binary_data(peer_id: int) -> Dictionary:
	var peer := 0x7fffffffffffffff
	var ret: Array
	while peer != peer_id:
		var timer := get_tree().create_timer(TIMEOUT)
		ret = await TimedPromise.new(timer, ws_server.binary_message).done
		if not ret:  #timed out
			return {}
		peer = ret[0]
	return {
		"peer_id": ret[0], "event": ret[1], "player_id": ret[2], "flags": ret[3], "data": ret[4]
	}

func parse_json(text: String) -> Result:
	var json := JSON.new()
	var error := json.parse(text)
	if error != OK:
		return Result.err(error)
	return Result.ok(json.data)


func get_json_data(peer_id: int) -> Result:
	var data := await get_text_data(peer_id)
	if data.is_empty():
		return Result.err(FAILED)
	return Result.ok(data)


func _get_verification(target_eid: int) -> Result:
	var eid := 0x7fffffffffffffff
	var ret: Array
	while eid != target_eid:
		ret = await server_controller.bridge.token_verification
		eid = ret[0]
		print(eid, " <- new verify | target -> ", target_eid)
	return ret[1] as Result


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
	var payload := JSON.stringify({"event": event, "player_id": origin_id, "details": details})
	for player_id: int in room.players.keys():
		var peer_id: int = room.players.getv(player_id).peer_id
		var error := ws_server.send_text(peer_id, payload)
		if error:
			return error
	return OK


func send_binary_event(event: int, details: PackedByteArray) -> Error:
	for player_id: int in room.players.keys():
		var peer_id: int = room.players.getv(player_id).peer_id
		var error := ws_server.send_targeted_binary(peer_id, event, details)
		if error:
			return error
	return OK


func update_player_status(player_id: int) -> void:
	send_event(
		"_is2_player_status_update",
		{"player_id": player_id, "status": room.players.getv(player_id).status}
	)


func update_player_operator_status(player_id: int) -> void:
	send_event(
		"_is2_player_operator_status_update",
		{"player_id": player_id, "operator": room.players.getv(player_id).operator}
	)


func sync_calendar() -> void:
	room.map.calendar.update_from_lpt = true
	send_event("calendar_sync", room.map.calendar.to_json())
	room.map.calendar.update_from_lpt = false


func close_room() -> void:
	for player_id: int in room.players.keys():
		@warning_ignore("unsafe_call_argument")
		ws_server.close(room.players.getv(player_id).peer_id)
	queue_free()


func _connected(peer_id: int, created: bool = false, _rid: int = -1) -> void:
	if room.players.size() >= room.player_limit:
		ws_server.close(peer_id, 6144, "The room is at maximum capacity.")
		return
	if ws_server.peer_ip(peer_id) in room.banned_ips:
		ws_server.close(peer_id, 6145, "You are banned from this room.")
		return
	room.id_iterator += 1
	var player_id := room.id_iterator
	while room.id_iterator in room.players.keys():
		room.id_iterator += 1

	if created:
		rid = _rid
		ws_server.send_targeted_event(
			peer_id,
			"_is2_room_info",
			{"room_id": server_controller._room_find_id(self), "player_id": player_id}
		)
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
			if password_json.is_err():
				ws_server.close(peer_id, 4096, "Protocol failure")
				return
			if password_json.val()["details"] == room.password:
				ws_server.send_targeted_event(peer_id, "_is2_login_valid_password")
				break
			ws_server.send_targeted_event(peer_id, "_is2_login_invalid_password", 5 - attempts)
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

	ws_server.send_targeted_event(peer_id, "_is2_token")
	var token_json := await get_json_data(peer_id)
	if ISUtil.valid_event_is(token_json, "_is2_token"):
		var token: Variant = token_json.val()["details"]
		if token == "" or token == null:
			player.logged_in = false
		else:
			var eid := server_controller.bridge.validate_token_request(token as String)
			var result := await _get_verification(eid)
			if result.is_err():
				ws_server.close(peer_id, 4101, "Invalid token")
				return
			else:
				player.logged_in = true
				player.username = result.val().username
				@warning_ignore("unsafe_call_argument")
				player.rank = UserEnums.variant_to_rank(result.val().rank)

	if created:
		player.operator = true
		room.creator_ip = ws_server.peer_ip(peer_id)

	room.players.setv(player_id, player)

	ws_server.send_targeted_event(
		peer_id,
		"_is2_handshake_complete",
		{"name": room.name, "description": room.description, "players": room.player_info()}
	)
	send_event("_is2_player_join", {"player_id": player_id, "details": player.get_info()})

	if created:
		server_controller.bridge.new_server(room, rid)
	else:
		var serialized := room.map.serialize()
		ws_server.send_targeted_chunk_data(peer_id, ISUtil.BinaryEvents.SYNC_MAP, serialized)
	
	
	room.map.calendar.update_from_lpt = true
	ws_server.send_targeted_event(peer_id, "calendar_sync", room.map.calendar.to_json())
	room.map.calendar.update_from_lpt = false

	room.player_ids_chronological.append(player_id)
	connected_peers.append(peer_id)


func parse_player_id(data: Variant) -> int:
	if not Verify.is_numeric(data):
		return NOT_VALID_PLAYER_ID
	@warning_ignore("unsafe_call_argument")
	return int(data)


func parse_event(data: Dictionary, peer_id: int) -> bool:
	if data["event"] is not String:
		return false
	var event: String = data["event"]
	if event.begins_with("mod:"):
		if not (room.players.getv(peer_player_id(peer_id)).rank >= UserEnums.Rank.MODERATOR):
			return false
	match event:
		"mod:roomblock_creator":
			var ip: String = room.creator_ip
			server_controller.roomblock(ip)
		"load_map":
			if room.players.getv(peer_player_id(peer_id)).privileged():
				var msg := await get_binary_data(peer_id)
				if msg["event"] != ISUtil.BinaryEvents.FORCE_RESYNC_MAP:
					return false #Dude. Uncool
				@warning_ignore("unsafe_call_argument")
				room.map = MapData.deserialize(msg["data"], true)
				send_binary_event(ISUtil.BinaryEvents.FORCE_RESYNC_MAP, msg["data"])
			return false
		"map_update":
			@warning_ignore("unsafe_call_argument")
			room.map.get_map_update(data["details"], peer_id)
		"typing_status":
			var id := peer_player_id(peer_id)
			room.players.getv(id).status["typing"] = data["details"]
			update_player_status(id)
		"change_rp_name":
			if ISUtil.validate_rp_name(data["details"] as String) or data["details"] == "":  #allow blanking to reset
				var id := peer_player_id(peer_id)
				room.players.getv(id).status["rp_name"] = data["details"]
				update_player_status(id)
		"map_resync":
			var serialized := room.map.serialize()
			ws_server.send_targeted_chunk_data(peer_id, ISUtil.BinaryEvents.SYNC_MAP, serialized)
		"dice":
			if (
				typeof(data["details"]["settings"]["min"]) != TYPE_FLOAT
				or typeof(data["details"]["settings"]["max"]) != TYPE_FLOAT
				or not Verify.array_is_type(data["details"]["position"], TYPE_FLOAT)
			):
				return false
			send_event(
				"dice_result",
				{
					"player_id": peer_player_id(peer_id),
					"position": data["details"]["position"],
					"result": DiceTool.roll(data["details"]["settings"] as Dictionary).to_data()
				}
			)
			return false
		"calendar_sync":
			if room.players.getv(peer_player_id(peer_id)).privileged():
				@warning_ignore("unsafe_call_argument")
				var tempcal := Calendar.from_json_safe(data["details"])
				if tempcal == null:
					return false
				room.map.calendar = tempcal
				if room.map.calendar.year < -1_000_000_000:
					room.map.calendar.year = -1_000_000_000
				if room.map.calendar.year > 1_000_000_000:
					room.map.calendar.year = 1_000_000_000
				sync_calendar()
				return false
			return false
		"ban":
			var id := parse_player_id(data["details"])
			if id == NOT_VALID_PLAYER_ID:
				return false
			var player: Player = room.players.getv(id)
			if room.players.getv(peer_player_id(peer_id)).privileged_over(player):
				var banned_peer: int = player.peer_id
				room.banned_ips.append(ws_server.peer_ip(banned_peer))
				ws_server.close(banned_peer, 5000, "Banned from this room")
		"kick":
			var id := parse_player_id(data["details"])
			if id == NOT_VALID_PLAYER_ID:
				return false
			var player: Player = room.players.getv(id)
			if room.players.getv(peer_player_id(peer_id)).privileged_over(player):
				var kicked_peer: int = player.peer_id
				ws_server.close(kicked_peer, 5001, "Kicked from this room")
		"mute":
			var id := parse_player_id(data["details"])
			if id == NOT_VALID_PLAYER_ID:
				return false
			var player: Player = room.players.getv(id)
			if room.players.getv(peer_player_id(peer_id)).privileged_over(player):
				player.status["muted"] = true
				update_player_status(id)
		"unmute":
			var id := parse_player_id(data["details"])
			if id == NOT_VALID_PLAYER_ID:
				return false
			var player: Player = room.players.getv(id)
			if room.players.getv(peer_player_id(peer_id)).privileged_over(player):
				player.status["muted"] = false
				update_player_status(id)
		"make_operator":
			var id := parse_player_id(data["details"])
			if id == NOT_VALID_PLAYER_ID:
				return false
			var player: Player = room.players.getv(id)
			if room.players.getv(peer_player_id(peer_id)).privileged():
				player.operator = true
				update_player_operator_status(id)
		"remove_operator":
			var id := parse_player_id(data["details"])
			if id == NOT_VALID_PLAYER_ID:
				return false
			var player: Player = room.players.getv(id)
			if room.players.getv(peer_player_id(peer_id)).privileged_over(player):
				player.operator = false
				update_player_operator_status(id)
		"purge_player":
			var id := parse_player_id(data["details"])
			if id == NOT_VALID_PLAYER_ID:
				return false
			var player: Player = room.players.getv(id)
			if room.players.getv(peer_player_id(peer_id)).privileged_over(player):
				revert_peer_drawing(id)
		"chat_message":
			var player: Player = room.players.getv(peer_player_id(peer_id))
			return not player.status.get("muted", false)

	#return value is true if it should be broadcasted to the rest of the server
	return true


func revert_peer_drawing(peer: int) -> void:
	var user: int = room.players.getv(peer).peer_id
	var pixel_list: PackedInt32Array = room.map.map_player_pixels.get(user, PackedInt32Array())
	for index in pixel_list:
		if room.map.map_last_painter[index] == user:
			var x := index % room.map.map_width
			var y := index / room.map.map_width
			room.map.image.set_pixel(x, y, room.map.map_last_color[index])
			room.map.map_last_painter[index] = -2
	room.map.map_player_pixels.erase(user)

	send_binary_event(ISUtil.BinaryEvents.FORCE_RESYNC_MAP, room.map.serialize())


func _closed(peer_id: int, _code: int, _reason: String) -> void:
	_on_peer_close(peer_id)


func _text_data(peer_id: int, data: Dictionary) -> void:
	if peer_id in connected_peers:
		var data_json := Result.ok(data)
		if ISUtil.valid_event(data_json):
			@warning_ignore("unsafe_call_argument")
			if await parse_event(data_json.val(), peer_id):
				@warning_ignore("unsafe_call_argument")
				send_event(
					data_json.val()["event"], data_json.val()["details"], peer_player_id(peer_id)
				)


@warning_ignore("unused_parameter")
func _binary_message(
	peer_id: int, event: int, player_id: int, flags: int, details: PackedByteArray
) -> void:
	if peer_id not in connected_peers:
		return
	if event == ISUtil.BinaryEvents.BRUSH_UPDATE:
		var brush_data := ISUtil.decode_brush_update(details)
		if brush_data.is_empty():
			return
		room.map.get_map_update(brush_data, peer_id)
		_broadcast_binary_to_others(peer_id, event, details)
	elif event == ISUtil.BinaryEvents.AVATAR_UPDATE:
		_broadcast_binary_to_others(peer_id, event, details)


## overwrites the uid with the real sender's player_id so receivers can't be spoofed
func _broadcast_binary_to_others(sender_peer_id: int, event: int, details: PackedByteArray) -> void:
	var sender_player_id := peer_player_id(sender_peer_id)
	for player_id: int in room.players.keys():
		var peer_id: int = room.players.getv(player_id).peer_id
		if peer_id != sender_peer_id:
			ws_server.send_targeted_binary(peer_id, event, details, true, sender_player_id)


func _ready() -> void:
	tasks.append(Task.new(sync_calendar, 5))

	## ctrl+k this to show the server map
	#var trect := TextureRect.new()
	#trect.texture = ImageTexture.create_from_image(room.map.image)
	#trect.scale = Vector2.ONE / 8
	#tasks.append(Task.new(func() -> void: trect.texture.update(room.map.image), 1))
	#add_child(trect)


func _process(delta: float) -> void:
	room.map.calendar.process(delta)
	for task in tasks:
		task.poll()
