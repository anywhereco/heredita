extends Label


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	text = tr("mainmenu/version") % ProjectSettings.get_setting("application/config/version")
	if ExportData.TYPE == ExportData.ReleaseType.EDITOR:
		text += " " + tr("mainmenu/version.editor")
	elif ExportData.TYPE == ExportData.ReleaseType.DEBUG:
		text += " " + (tr("mainmenu/version.commit") % ExportData.COMMIT)
