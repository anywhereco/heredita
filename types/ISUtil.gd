extends Node
class_name ISUtil

enum BinaryFlags {
	NONE = 0,
	COMPRESSED = 1,
	BEGIN_CHUNK = 2,
	LAST_CHUNK = 4
}

enum BinaryEvents {
	#chunked events start at 0x80
	SYNC_MAP = 0x80
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
	return Color(color[0], color[1], color[2])

static func from_vec2(vec: Vector2) -> Array:
	return [vec.x, vec.y]
	
static func to_vec2(vec: Array) -> Vector2:
	return Vector2(vec[0], vec[1])
