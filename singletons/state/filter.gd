extends Node
class_name TextFilter

enum {
	MODE_NONE,
	MODE_OFFENSIVE,
	MODE_FULL
}

static var filter_mode := MODE_OFFENSIVE

const filter_offensive = [
	"fag"
]

const filter_other = [
	"fuck"
]

static func grawlix(text: String) -> String:
	return "*".repeat(text.length())

static func substr_replace(text: String, with: String, start: int, end: int) -> String:
	return text.substr(0,start) + with + text.substr(end)

static func filter_text(text: String) -> String:
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
