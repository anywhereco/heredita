class_name Server2ServerBridge
extends Node

static var event_id := 0

var socket := WebSocketPeer.new()
var controller: ServerController

signal token_verification(for_id: int, res: Result)

static func get_event_id() -> int:
	event_id += 1
	return event_id

func _init(_controller: ServerController) -> void:
	controller = _controller
	socket.connect_to_url("ws" + Statics.HEREDITA_URL.right(-4) + "/__internal__heredita__/s2s")

func get_msg() -> Dictionary:
	var pkt := socket.get_packet().get_string_from_utf8()
	return JSON.parse_string(pkt)

func poll() -> void:
	if socket.get_ready_state() != socket.STATE_CLOSED:
		socket.poll()
	while socket.get_ready_state() == socket.STATE_OPEN and socket.get_available_packet_count():
		_poll_loop()

func _poll_loop() -> void:
	var message := get_msg()
	match message["event"]:
		"roomlist": 
			var rooms_json: Dictionary = {}
			for room in controller.rooms:
				rooms_json[room] = controller.rooms[room].room.to_json()
			send_event("roomlist_response", {"rooms": rooms_json})
		"validated":
			@warning_ignore("unsafe_call_argument")
			token_verification.emit(message.eid, Result.ok(UserPartial.new(message.user_id, message.user, UserEnums.string_to_rank(message.rank))))
		"invalid_token":
			token_verification.emit(message.eid, Result.err(-1))

func send_event(event: String, content: Dictionary[String, Variant]) -> int:
	content["event"] = event
	var eid := get_event_id()
	content["eid"] = get_event_id()
		
	socket.send_text(JSON.stringify(content))
	return eid

func validate_token_request(token: String) -> int:
	return send_event("validate", {"token": token})

func _process(_delta: float) -> void:
	poll()
