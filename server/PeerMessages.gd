class_name PeerMessages
extends RefCounted

const TIMEOUT_SECONDS := 300.0

var _server: WSServer
var _timeout_seconds: float


func _init(server: WSServer, timeout_seconds: float = TIMEOUT_SECONDS) -> void:
	_server = server
	_timeout_seconds = timeout_seconds


func text(peer_id: int) -> Result:
	var packet := await _wait(peer_id, _server.text_data)
	if packet.is_empty() or not packet[1] is Dictionary or packet[1].is_empty():
		return Result.err(FAILED)
	return Result.ok(packet[1])


func binary(peer_id: int) -> Dictionary:
	var packet := await _wait(peer_id, _server.binary_message)
	if packet.is_empty():
		return {}
	return {
		"peer_id": packet[0], "event": packet[1], "player_id": packet[2],
		"flags": packet[3], "data": packet[4]
	}


func _wait(peer_id: int, incoming: Signal) -> Array:
	var pending := PendingMessage.new(peer_id)
	var timer: SceneTreeTimer
	if _timeout_seconds > 0.0:
		timer = _server.get_tree().create_timer(_timeout_seconds)
		timer.timeout.connect(pending.timed_out)
	incoming.connect(pending.received)
	_server.closed.connect(pending.closed)
	var packet: Array = await pending.done
	incoming.disconnect(pending.received)
	_server.closed.disconnect(pending.closed)
	if timer != null:
		timer.timeout.disconnect(pending.timed_out)
	return packet


class PendingMessage:
	extends RefCounted

	signal done(packet: Array)

	var peer_id: int

	func _init(id: int) -> void:
		peer_id = id

	func received(...packet: Array) -> void:
		if packet[0] == peer_id:
			done.emit(packet)

	func closed(id: int, _code: int, _reason: String) -> void:
		if id == peer_id:
			done.emit([])

	func timed_out() -> void:
		done.emit([])
