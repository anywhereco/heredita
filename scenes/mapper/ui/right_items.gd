extends VBoxContainer

var have_processed: bool = false

const MAX_DEFAULT_CHAT_WIDTH := 225


func _ready() -> void:
	pass


func _process(_delta: float) -> void:
	if not have_processed:
		if size.x >= MAX_DEFAULT_CHAT_WIDTH:
			size_flags_stretch_ratio = (MAX_DEFAULT_CHAT_WIDTH / size.x)
		have_processed = true
	# TODO: maybe always change on resize? user can still manually resize the chat bar if they want anyway
