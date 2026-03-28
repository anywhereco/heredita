extends Label


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	text = text % [ProjectSettings.get_setting("application/config/version")]
	if ExportData.TYPE == ExportData.ReleaseType.EDITOR:
		text += " (editor build)"
	elif ExportData.TYPE == ExportData.ReleaseType.DEBUG:
		text += " (commit %s)" % ExportData.COMMIT
