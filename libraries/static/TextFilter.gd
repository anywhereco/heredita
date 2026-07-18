class_name TextFilter

enum { MODE_NONE, MODE_OFFENSIVE, MODE_FULL }

static var filter_mode := MODE_OFFENSIVE

static var filter_offensive := []
static var filter_other := []

static var _compiled_offensive: Array[RegEx] = []
static var _compiled_full: Array[RegEx] = []


static func _static_init() -> void:
	while not HTTP:
		await RenderingServer.frame_pre_draw
	if HTTP.is_node_ready():
		load_filter_lists()
	else:
		HTTP.ready.connect(load_filter_lists)


static func load_filter_lists() -> void:
	var filters := await HTTP.request(Statics.HEREDITA_URL, "filter")
	if filters.is_err():
		return
	filter_offensive = filters.val().get("offensive")
	filter_other = filters.val().get("other")
	_compile_filters()


static func _compile_filters() -> void:
	_compiled_offensive.clear()
	_compiled_full.clear()
	for word: String in filter_offensive:
		_compiled_offensive.append(
			RegEx.create_from_string("(?i)(?<![A-Z])%s(?:s?)(?![A-Z])" % word)
		)
	for word: String in filter_offensive + filter_other:
		_compiled_full.append(RegEx.create_from_string("(?i)(?<![A-Z])%s(?:s?)(?![A-Z])" % word))


static func grawlix(text: String) -> String:
	return "-".repeat(text.length())


static func filter_text(text: String) -> String:
	filter_mode = Settings.getv("filter_mode")
	if filter_mode == MODE_NONE:
		return text
	var regexes: Array[RegEx] = (
		_compiled_offensive if filter_mode == MODE_OFFENSIVE else _compiled_full
	)
	for regex: RegEx in regexes:
		for m: RegExMatch in regex.search_all(text):
			text = (
				text.substr(0, m.get_start()) + grawlix(m.get_string()) + text.substr(m.get_end())
			)
	return text
