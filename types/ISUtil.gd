extends Node
class_name ISUtil

enum BinaryFlags { 
	NONE = 0,
	COMPRESSED = 1 << 0,
	CHUNK_START_HEADER = 1 << 1,
	CHUNK_PART = 1 << 2,
}

enum BinaryEvents {
	SYNC_MAP = 0x0,
	SYNC_MAP_END = 0x1,
	SYNC_MAP_SIZE = 0x2,  # used on server only
	#chunked events start at 0x8000
	TODO_SYNC_MAP = 0x8000
}


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
	@warning_ignore("unsafe_call_argument")
	return Color(color[0], color[1], color[2])


static func from_vec2(vec: Vector2) -> Array:
	return [vec.x, vec.y]


static func to_vec2(vec: Array) -> Vector2:
	@warning_ignore("unsafe_call_argument")
	return Vector2(vec[0], vec[1])


static func from_vec3(vec: Vector3) -> Array:
	return [vec.x, vec.y, vec.z]


static func to_vec3(vec: Array) -> Vector3:
	@warning_ignore("unsafe_call_argument")
	return Vector3(vec[0], vec[1], vec[2])
