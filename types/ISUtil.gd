extends Node
class_name ISUtil

static func json_event(dict: Dictionary) -> Variant:
	return dict.get("event")

static func json_event_from_result(result: Result) -> String:
	return ISUtil.json_event(result.val() as Dictionary)
	
static func valid_event(result: Result) -> bool:
	return result.is_ok() and ISUtil.json_event(result.val() as Dictionary)

static func valid_event_is(result: Result, event: String) -> bool:
	return result.is_ok() and ISUtil.json_event(result.val() as Dictionary) == event
