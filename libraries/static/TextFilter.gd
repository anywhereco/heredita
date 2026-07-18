class_name TextFilter

enum {
	MODE_NONE,
	MODE_OFFENSIVE,
	MODE_FULL
}

static var filter_mode := MODE_OFFENSIVE

static var filter_offensive := []

static var filter_other := []

static func _static_init() -> void:
	while not HTTP:
		await RenderingServer.frame_pre_draw
	if HTTP.is_node_ready():
		load_filter_lists()
	else:
		HTTP.ready.connect(load_filter_lists)

static func load_filter_lists() -> void:
	var filters := await HTTP.request(Statics.HEREDITA_URL, "filter")
	#if filter doesnt work the rest probably doesnt work either. so idk
	if filters.is_err():
		return
	filter_offensive = filters.val().get("offensive")
	filter_other = filters.val().get("other")

static func grawlix(text: String) -> String:
	return "-".repeat(text.length())

static func substr_replace(text: String, with: String, start: int, end: int) -> String:
	return text.substr(0,start) + with + text.substr(end)

static func filter_text(text: String) -> String:
	filter_mode = Settings.getv("filter_mode")
	if filter_mode == MODE_NONE:
		return text
	var to_filter := filter_offensive
	if filter_mode == MODE_FULL:
		to_filter = filter_offensive + filter_other
	for word: String in to_filter:
		var regex := RegEx.create_from_string("(?i)(?<![A-Z])%s(?:s?)(?![A-Z])" % word)
		var matches := regex.search_all(text)
		for m: RegExMatch in matches:
			text = substr_replace(text, grawlix(m.get_string()), m.get_start(), m.get_end())
	return text
