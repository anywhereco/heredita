extends Node
class_name WSServer

var PORT := 443
const BUFFER_SIZE_KB := 2048

var _tcp_server: TCPServer = TCPServer.new()

var _peers: Dictionary[int, WebSocketPeer] = {}
var _peer_status: Dictionary[int, WebSocketPeer.State] = {}

var last_peer_id := 1

func _ready() -> void:
	var args := OS.get_cmdline_user_args()
	for arg in args:
		if arg.begins_with("--server-port="):
			PORT = int(arg.split("=")[1])
	print(PORT)
	var err := _tcp_server.listen(PORT)
	if err == OK:
		print("Server started.")
	else:
		push_error("Unable to start server.")
		set_process(false)

signal text_data(peer_id: int, data: String)

signal binary_data(peer_id: int, data: PackedByteArray)

signal connected(peer_id: int)

signal closed(peer_id: int, code: int, reason: String)

func peer_ip(peer_id: int) -> String:
	return _peers[peer_id].get_connected_host()

func send_text(peer_id: int, message: String) -> Error:
	var peer := _peers[peer_id]
	var error := peer.send_text(message)
	return error
	
func send_raw_binary(peer_id: int, message: PackedByteArray) -> Error:
	var peer := _peers[peer_id]
	var error := peer.send(message)
	return error
	
func send_targeted_event(peer_id: int, event: String, details: Variant = {}, origin_id := -1) -> Error:
	if details:
		return send_text(peer_id, JSON.stringify({"event": event, "player_id": origin_id, "details": details}))
	return send_text(peer_id, JSON.stringify({"event": event, "player_id": origin_id}))

func send_targeted_binary(peer_id: int, event: int, message: PackedByteArray, flags: int = 0, compress: bool = true) -> int:
	assert(event >= 0 and event <= 65535, "The event value should fit within a 16-bit int")
	var compression_size: int
	if compress:
		flags |= ISUtil.BinaryFlags.COMPRESSED
		compression_size = len(message)
		message = message.compress(FileAccess.COMPRESSION_FASTLZ)
	var bytes := PackedByteArray()
	bytes.resize(5)
	bytes.encode_u16(0, event)
	var target := 0 #unnecessary for server messages
	bytes.encode_s16(2, target)
	bytes.encode_u8(4, flags)
	if compress:
		bytes.resize(9)
		bytes.encode_u32(5, compression_size)
	bytes.append_array(message)
	return send_raw_binary(peer_id, bytes)
	
func send_global_event(event: String, details: Dictionary, origin_id := -1) -> Error:
	for peer_id: int in _peers:
		var error := send_text(peer_id, JSON.stringify({"event": event, "player_id": origin_id, "details": details}))
		if error:
			return error
	return OK

func close(peer_id: int, code := 1000, reason := "") -> void:
	var peer := _peers[peer_id]
	peer.close(code, reason)

func _process(_delta: float) -> void:
	while _tcp_server.is_connection_available():
		last_peer_id += 1
		print("peer %d connected" % last_peer_id)
		var ws := WebSocketPeer.new()
		ws.outbound_buffer_size = BUFFER_SIZE_KB * 1024
		ws.inbound_buffer_size = BUFFER_SIZE_KB * 1024
		ws.accept_stream(_tcp_server.take_connection())
		_peers[last_peer_id] = ws
		_peer_status[last_peer_id] = WebSocketPeer.STATE_CONNECTING

	# Iterate over all connected peers using "keys()" so we can erase in the loop
	for peer_id: int in _peers.keys():
		var peer := _peers[peer_id]

		peer.poll()

		var peer_state := peer.get_ready_state()
		if _peer_status[peer_id] != WebSocketPeer.STATE_OPEN and peer_state == WebSocketPeer.STATE_OPEN:
			connected.emit(peer_id)
		_peer_status[peer_id] = peer_state
		if peer_state == WebSocketPeer.STATE_OPEN:
			while peer.get_available_packet_count():
				var packet := peer.get_packet()
				if peer.was_string_packet():
					var packet_text := packet.get_string_from_utf8()
					text_data.emit(peer_id, packet_text)
				else:
					binary_data.emit(peer_id, packet)
		elif peer_state == WebSocketPeer.STATE_CLOSED:
			# Remove the disconnected peer.
			_peers.erase(peer_id)
			_peer_status.erase(peer_id)
			var code := peer.get_close_code()
			var reason := peer.get_close_reason()
			closed.emit(peer_id, code, reason)
