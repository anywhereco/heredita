class_name ExportData extends RefCounted

enum ReleaseType { EDITOR, DEBUG, RELEASE }

static var BUILD_STR = "editor-" + Time.get_datetime_string_from_system(true)

static var COMMIT = "unknown (editor build)"

static var TYPE = ReleaseType.EDITOR
