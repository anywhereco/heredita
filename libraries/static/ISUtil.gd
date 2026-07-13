class_name ISUtil

const BUFFER_SIZE_KB: int = 2048
const LARGE_PACKET_BUDGET: int = (BUFFER_SIZE_KB * 1024) - 65536
const MAX_CHANNELS: int = 2
const PACKETS_PER_CHANNEL: int = 4

enum BinaryFlags {
	NONE = 0,
	COMPRESSED = 1 << 0,
	CHUNK_START_HEADER = 1 << 1,
	CHUNK_PART = 1 << 2,
	CHUNK_PART_LAST = 1 << 3,
}

enum BinaryEvents {SYNC_MAP = 0x0, FORCE_RESYNC_MAP = 0x1, BRUSH_UPDATE = 0x2, AVATAR_UPDATE = 0x3}


static func validate_rp_name(name: String) -> bool:  #might be used for more things later idk
	if not name.strip_edges():  #basic whitespace check; maybe use something stronger for weird unicode characters in the future
		return false
	if len(name) == 0:
		return false
	if len(name) > 64:
		return false
	#maybe also an offensive-filter check?
	return true


## Returns "" if not a valid event.
static func is_event(data: Variant) -> String:
	if typeof(data) != TYPE_DICTIONARY:
		return ""
	return data.get("event", "")


static func json_event(dict: Dictionary) -> Variant:
	return dict.get("event")


static func json_event_from_result(result: Result) -> String:
	return ISUtil.json_event(result.val() as Dictionary)


static func valid_event(result: Result) -> bool:
	return result.is_ok() and ISUtil.json_event(result.val() as Dictionary)


static func valid_event_is(result: Result, event: String) -> bool:
	return result.is_ok() and ISUtil.json_event(result.val() as Dictionary) == event


static func from_color(color: Color) -> Array:
	return [color.r, color.g, color.b]


static func to_color(color: Array) -> Color:
	if color.size() >= 3:
		@warning_ignore("unsafe_call_argument")
		return Color(color[0], color[1], color[2])
	else:
		assert(false, "Color is too small")
		return Color.WHITE


static func from_vec2(vec: Vector2) -> Array:
	return [vec.x, vec.y]


static func to_vec2(vec: Array) -> Vector2:
	if vec.size() >= 2:
		@warning_ignore("unsafe_call_argument")
		return Vector2(vec[0], vec[1])
	else:
		assert(false, "Vec2 is too small")
		return Vector2.ZERO


static func from_vec3(vec: Vector3) -> Array:
	return [vec.x, vec.y, vec.z]


static func to_vec3(vec: Array) -> Vector3:
	if vec.size() >= 2:
		@warning_ignore("unsafe_call_argument")
		return Vector3(vec[0], vec[1], vec[2])
	else:
		assert(false, "Vec2 is too small")
		return Vector3.ZERO


## layout: pos_x(f32) + pos_y(f32) + size(u8) + paint_rgb(3*u8) + target_rgb(3*u8) + targeted(u8)
static func encode_brush_update(
	pos: Vector2, size: int, paint_color: Color, target_color: Color, targeted: bool
) -> PackedByteArray:
	var bytes := PackedByteArray()
	bytes.resize(16)
	bytes.encode_float(0, pos.x)
	bytes.encode_float(4, pos.y)
	bytes.encode_u8(8, size)
	bytes.encode_u8(9, int(paint_color.r * 255))
	bytes.encode_u8(10, int(paint_color.g * 255))
	bytes.encode_u8(11, int(paint_color.b * 255))
	bytes.encode_u8(12, int(target_color.r * 255))
	bytes.encode_u8(13, int(target_color.g * 255))
	bytes.encode_u8(14, int(target_color.b * 255))
	bytes.encode_u8(15, 1 if targeted else 0)
	return bytes


## Returns a dictionary matching the json map_update format
static func decode_brush_update(data: PackedByteArray) -> Dictionary:
	if data.size() < 16:
		return {}
	return {
		"type": "brush",
		"pos": [data.decode_float(0), data.decode_float(4)],
		"size": float(data.decode_u8(8)),
		"paint_color":
		[data.decode_u8(9) / 255.0, data.decode_u8(10) / 255.0, data.decode_u8(11) / 255.0],
		"target_color":
		[data.decode_u8(12) / 255.0, data.decode_u8(13) / 255.0, data.decode_u8(14) / 255.0],
		"targeted": data.decode_u8(15) != 0
	}


## layout: pos(3*f32) + rot(3*f32) + vel(3*f32) + cam_rot(f32) + jump(u8)
static func encode_avatar_update(
	pos: Vector3, rot: Vector3, vel: Vector3, cam_rot: float, jump: bool
) -> PackedByteArray:
	var bytes := PackedByteArray()
	bytes.resize(41)
	bytes.encode_float(0, pos.x)
	bytes.encode_float(4, pos.y)
	bytes.encode_float(8, pos.z)
	bytes.encode_float(12, rot.x)
	bytes.encode_float(16, rot.y)
	bytes.encode_float(20, rot.z)
	bytes.encode_float(24, vel.x)
	bytes.encode_float(28, vel.y)
	bytes.encode_float(32, vel.z)
	bytes.encode_float(36, cam_rot)
	bytes.encode_u8(40, 1 if jump else 0)
	return bytes


## Decode an avatar update from a binary message.
static func decode_avatar_update(data: PackedByteArray) -> Dictionary:
	if data.size() < 41:
		return {}
	return {
		"position": [data.decode_float(0), data.decode_float(4), data.decode_float(8)],
		"rotation": [data.decode_float(12), data.decode_float(16), data.decode_float(20)],
		"velocity": [data.decode_float(24), data.decode_float(28), data.decode_float(32)],
		"camera_rotation": data.decode_float(36),
		"jump": data.decode_u8(40) != 0
	}


static func debug_print_array(arr: PackedByteArray, pre: Variant = "") -> void:
	if arr.size() < 12:
		print(pre, arr)
	else:
		print(
			pre,
			"%08x" % arr.decode_u32(0),
			"... [",
			arr.size(),
			" bytes] ...",
			"%08x" % arr.decode_u32(arr.size() - 4)
		)


static func test_flags(flags: int, test: int) -> bool:
	return flags & test


static func message_is_chunking_related(message: PackedByteArray) -> bool:
	var flags := message.decode_u8(4)
	return flags & (BinaryFlags.CHUNK_START_HEADER | BinaryFlags.CHUNK_PART)


static func _parse_binary(message: PackedByteArray) -> Dictionary:
	var flags := message.decode_u8(0)
	var event := message.decode_u16(1)
	var uid := message.decode_s16(3)
	var header_size := 5 + (4 if test_flags(flags, BinaryFlags.COMPRESSED) else 0)
	var data := message.slice(header_size)
	var offset := 5
	if test_flags(flags, BinaryFlags.COMPRESSED):
		var compression_size := message.decode_u32(offset)
		offset += 4
		data = data.decompress(compression_size, FileAccess.COMPRESSION_FASTLZ)
	return {"event": event, "uid": uid, "flags": flags, "data": data}


static func _create_binary(
	event: int, target: int, message: PackedByteArray, compress: bool
) -> PackedByteArray:
	assert(event >= 0 and event <= 65535, "The event value should fit within a 16-bit int")
	assert(
		target >= -32768 and target <= 32767,
		"The target value should fit within a 16-bit signed int"
	)
	var size := 5 + (4 if compress else 0)
	var flags := 0
	var compression_size: int
	if compress:
		@warning_ignore("int_as_enum_without_cast")
		flags = ISUtil.BinaryFlags.COMPRESSED
		compression_size = len(message)
		message = message.compress(FileAccess.COMPRESSION_FASTLZ)
	var bytes := PackedByteArray()
	bytes.resize(size)
	bytes.encode_u8(0, flags)
	bytes.encode_u16(1, event)
	bytes.encode_s16(3, target)
	if compress:
		bytes.encode_u32(5, compression_size)
	bytes.append_array(message)
	return bytes


class ChunkSender:
	extends RefCounted

	signal chunk_recieved(id: int)

	var current_channel_count: int = 0

	var chunk_id: int = 0

	## The expected format for the send callable is a one-parameter function that takes in a PackedByteArray.
	var send_to_socket: Callable

	static func _create_chunk_header(
		event: int, target: int, uncompressed_size: int, channel: int
	) -> PackedByteArray:
		var bytes := PackedByteArray()
		bytes.resize(10)
		bytes.encode_u8(0, BinaryFlags.CHUNK_START_HEADER)
		bytes.encode_u16(1, event)
		bytes.encode_s16(3, target)
		bytes.encode_u32(5, uncompressed_size)
		bytes.encode_u8(9, channel)
		return bytes

	static func _create_chunk_data(
		_chunk_id: int, channel: int, chunk_data: PackedByteArray, last: bool
	) -> PackedByteArray:
		var bytes := PackedByteArray()
		bytes.resize(6)
		bytes.encode_u8(0, BinaryFlags.CHUNK_PART | (BinaryFlags.CHUNK_PART_LAST if last else 0))
		bytes.encode_u16(1, (_chunk_id >> 8) & 0xFFFF)
		bytes.encode_u8(3, (_chunk_id) & 0xFF)
		bytes.encode_u8(4, channel)
		bytes.append_array(chunk_data)
		return bytes

	func _init(_send: Callable) -> void:
		send_to_socket = _send

	func increment_chunk_id() -> int:
		chunk_id += 1
		chunk_id &= 0xFFFFFF
		return chunk_id

	func send(event: int, target: int, message: PackedByteArray) -> Error:
		if current_channel_count == MAX_CHANNELS:
			return ERR_BUSY
		var channel := current_channel_count
		current_channel_count += 1

		var uncompressed_size := message.size()
		message = message.compress(FileAccess.COMPRESSION_FASTLZ)

		var size := message.size()

		@warning_ignore("integer_division")
		var chunk_size := LARGE_PACKET_BUDGET / (PACKETS_PER_CHANNEL * MAX_CHANNELS)

		var total_chunk_count := ceili(message.size() / (chunk_size as float))
		var chunk_ids: Array[int] = []

		chunk_recieved.connect(func(id: int) -> void: chunk_ids.erase(id))
		send_to_socket.call(_create_chunk_header(event, target, uncompressed_size, channel))

		for chunk_count in range(total_chunk_count):
			while chunk_ids.size() >= PACKETS_PER_CHANNEL:
				await chunk_recieved
			chunk_ids.append(chunk_id)

			var chunk_data := message.slice(
				chunk_count * chunk_size, mini((chunk_count + 1) * chunk_size, size)
			)
			send_to_socket.call(
				_create_chunk_data(
					chunk_id, channel, chunk_data, chunk_count == (total_chunk_count - 1)
				)
			)
			increment_chunk_id()

		current_channel_count -= 1
		return OK


class ChunkReceiver:
	extends RefCounted

	signal chunked_message(event: int, target: int, data: PackedByteArray)

	signal chunk_received(id: int)

	## The int key is the channel of the message, since there cannot be two messages at once in the same channel.
	var messages: Dictionary[int, PackedByteArray]
	var message_uncompressed_sizes: Dictionary[int, int]
	var message_targets: Dictionary[int, int]
	var message_events: Dictionary[int, int]

	## Returns whether the message is chunking related [i.e. if it has been handled by the chunking system]
	func handle_potential_chunked_message(message: PackedByteArray) -> bool:
		var flags := message.decode_u8(0)
		if not (flags & (BinaryFlags.CHUNK_START_HEADER | BinaryFlags.CHUNK_PART)):
			return false  # if this isn't chunking related we want to fast path this
		if flags & BinaryFlags.CHUNK_START_HEADER:
			var event := message.decode_u16(1)
			var target := message.decode_s16(3)
			var uncompressed_size := message.decode_u32(5)
			var channel := message.decode_u8(9)
			message_events[channel] = event
			message_targets[channel] = target
			message_uncompressed_sizes[channel] = uncompressed_size
			if not messages.has(channel):
				messages[channel] = PackedByteArray()
		if flags & BinaryFlags.CHUNK_PART:
			var chunk_id := (message.decode_u16(1) << 8) | message.decode_u8(3)
			var channel := message.decode_u8(4)
			messages[channel].append_array(message.slice(6))
			chunk_received.emit(chunk_id)
			if flags & BinaryFlags.CHUNK_PART_LAST:
				var decompressed := messages[channel].decompress(
					message_uncompressed_sizes[channel], FileAccess.COMPRESSION_FASTLZ
				)
				chunked_message.emit(
					message_events[channel], message_targets[channel], decompressed
				)
				messages[channel] = PackedByteArray()  # Since messages can be very large, we clean up the data here.
		return true
