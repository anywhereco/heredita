class_name ExportTimeDataExportPlugin extends EditorExportPlugin

var debug: bool = false


func _get_name() -> String:
	return "Export Time Data Provider"


const TEMPLATE = """
class_name ExportData extends RefCounted

enum ReleaseType { EDITOR, DEBUG, RELEASE }

static var BUILD_STR = "{type}-{date}"

static var COMMIT = "{commit}"

static var TYPE = ReleaseType.{typeCaps}
"""


func _export_begin(features: PackedStringArray, is_debug: bool, path: String, flags: int) -> void:
	debug = is_debug


func _export_file(path: String, type: String, features: PackedStringArray) -> void:
	if path.contains("exporttime_data.gd"):
		var result := []
		OS.execute(
			"git",
			["-C", ProjectSettings.globalize_path("res://"), "rev-parse", "--short", "HEAD"],
			result
		)
		var content := TEMPLATE.format(
			{
				"date": Time.get_datetime_string_from_system(true),
				"type": "debug" if debug else "release",
				"typeCaps": "DEBUG" if debug else "RELEASE",
				"commit": result[0].strip_edges()
			}
		)
		add_file(path, content.to_utf8_buffer(), true)
