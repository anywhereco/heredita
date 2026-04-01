extends Node
class_name WSServer

var PORT := 443

var x509_cert: X509Certificate = null
var private_key: CryptoKey = null
var tlsoptions: TLSOptions = null

const BUFFER_SIZE_KB := 2048

var _tcp_server: TCPServer = TCPServer.new()

var _peers: Dictionary[int, WebSocketPeer] = {}
var _peer_status: Dictionary[int, WebSocketPeer.State] = {}
## Will be empty if TLS is disabled.
var _peer_tls: Dictionary[int, StreamPeerTLS] = {}
var _peer_chunk_senders: Dictionary[int, ISUtil.ChunkSender] = {}
var _peer_chunk_receivers: Dictionary[int, ISUtil.ChunkReceiver] = {}

var last_peer_id := 1


func _ready() -> void:
	var args := OS.get_cmdline_user_args()
	for arg in args:
		if arg.begins_with("--server-port="):
			PORT = int(arg.split("=")[1])
		if arg.begins_with("--certificate-path="):
			x509_cert = X509Certificate.new()
			var x509_err := x509_cert.load(arg.split("=")[1])
			if x509_err:
				push_error("Failed to set the x509 certificate, exiting! Error code ", x509_err)
				get_tree().quit()
		if arg.begins_with("--private-key="):
			private_key = CryptoKey.new()
			var pk_err := private_key.load(arg.split("=")[1])
			if pk_err:
				push_error("Failed to set the private key, exiting! Error code ", pk_err)
				get_tree().quit()
	if x509_cert == null and private_key == null:
		if OS.has_feature("editor"):
			print("Running without a certificate.")
		elif OS.has_feature("debug"):
			push_warning("Running without a certificate! This might not be what you want.")
		else:
			push_error("Running without a certificate, exiting! You can get around this by using a debug build.")
			get_tree().quit()
	elif x509_cert != null and private_key != null:
		print("We signed up in here :DDDD")
		tlsoptions = TLSOptions.server(private_key, x509_cert)
	else:
		push_error("Only a private key or certificate was set, you need both. Exiting!")
		get_tree().quit()
		
	print(PORT)
	var err := _tcp_server.listen(PORT)
	if err == OK:
		print("Server started.")
	else:
		push_error("Unable to start server.")
		breakpoint
		set_process(false)


signal text_data(peer_id: int, data: String)

signal binary_message(
	peer_id: int, event: int, player_id: int, flags: int, details: PackedByteArray
)

signal connected(peer_id: int)

signal closed(peer_id: int, code: int, reason: String)


func peer_ip(peer_id: int) -> String:
	return _peers[peer_id].get_connected_host()


func peer_available(peer_id: int) -> bool:
	if peer_id not in _peers:
		return false
	var peer_state := _peers[peer_id].get_ready_state()
	return peer_state != WebSocketPeer.STATE_CLOSING and peer_state != WebSocketPeer.STATE_CLOSED


func send_text(peer_id: int, message: String) -> Error:
	if not peer_available(peer_id):
		return FAILED
	var peer := _peers[peer_id]
	var error := peer.send_text(message)
	return error


func send_raw_binary(peer_id: int, message: PackedByteArray) -> Error:
	if not peer_available(peer_id):
		return FAILED
	var peer := _peers[peer_id]
	var error := peer.send(message)
	return error


func send_targeted_event(
	peer_id: int, event: String, details: Variant = {}, origin_id := -1
) -> Error:
	if details != null:
		return send_text(
			peer_id, JSON.stringify({"event": event, "player_id": origin_id, "details": details})
		)
	return send_text(peer_id, JSON.stringify({"event": event, "player_id": origin_id}))


func send_targeted_chunk_data(peer_id: int, event: int, message: PackedByteArray) -> int:
	return await _peer_chunk_senders[peer_id].send(event, 0, message)


func send_targeted_binary(
	peer_id: int, event: int, message: PackedByteArray, compress: bool = true
) -> int:
	return send_raw_binary(peer_id, ISUtil._create_binary(event, 0, message, compress))


func send_global_event(event: String, details: Dictionary, origin_id := -1) -> Error:
	for peer_id: int in _peers:
		var error := send_text(
			peer_id, JSON.stringify({"event": event, "player_id": origin_id, "details": details})
		)
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
		if tlsoptions != null:
			_peer_tls[last_peer_id] = StreamPeerTLS.new()
			_peer_tls[last_peer_id].accept_stream(_tcp_server.take_connection(), tlsoptions)
			ws.accept_stream(_peer_tls[last_peer_id])
		else:
			ws.accept_stream(_tcp_server.take_connection())
		_peers[last_peer_id] = ws
		_peer_status[last_peer_id] = WebSocketPeer.STATE_CONNECTING
		_peer_chunk_senders[last_peer_id] = ISUtil.ChunkSender.new(
			func(data: PackedByteArray) -> void: ws.send(data)
		)
		_peer_chunk_receivers[last_peer_id] = ISUtil.ChunkReceiver.new()
		_peer_chunk_receivers[last_peer_id].chunk_received.connect(
			func(id: int) -> void: send_targeted_event(last_peer_id, "_is2_chunk_received", id)
		)
		_peer_chunk_receivers[last_peer_id].chunked_message.connect(
			func(event: int, target: int, data: PackedByteArray) -> void:
				binary_message.emit(last_peer_id, event, target, ISUtil.BinaryFlags.NONE, data)
		)

	# Iterate over all connected peers using "keys()" so we can erase in the loop
	for peer_id: int in _peers.keys():
		var peer := _peers[peer_id]

		peer.poll()

		var peer_state := peer.get_ready_state()
		if (
			_peer_status[peer_id] != WebSocketPeer.STATE_OPEN
			and peer_state == WebSocketPeer.STATE_OPEN
		):
			connected.emit(peer_id)
		_peer_status[peer_id] = peer_state
		if peer_state == WebSocketPeer.STATE_OPEN:
			while peer.get_available_packet_count():
				var packet := peer.get_packet()
				if peer.was_string_packet():
					var packet_text := packet.get_string_from_utf8()
					var event: Variant = JSON.parse_string(packet_text)
					if ISUtil.is_event(event) == "_is2_chunk_received":
						_peer_chunk_senders[peer_id].chunk_recieved.emit(event.details)
						return
					if ISUtil.is_event(event) == "_is2_ping":
						send_targeted_event(peer_id, "_is2_pong")
						return
					text_data.emit(peer_id, packet_text)
				else:
					if _peer_chunk_receivers[peer_id].handle_potential_chunked_message(packet):
						return
					var data := ISUtil._parse_binary(packet)
					binary_message.emit(peer_id, data.event, data.target, data.flags, data.details)
		elif peer_state == WebSocketPeer.STATE_CLOSED:
			# Remove the disconnected peer.
			_peers.erase(peer_id)
			_peer_status.erase(peer_id)
			var code := peer.get_close_code()
			var reason := peer.get_close_reason()
			print("server close (%d): %s" % [code, reason])
			closed.emit(peer_id, code, reason)
