@tool
extends EditorPlugin


func _enable_plugin() -> void:
	# Add autoloads here.
	pass


func _disable_plugin() -> void:
	# Remove autoloads here.
	pass


var export_plugin: ExportTimeDataExportPlugin


func _enter_tree() -> void:
	export_plugin = ExportTimeDataExportPlugin.new()
	add_export_plugin(export_plugin)


func _exit_tree() -> void:
	if is_instance_valid(export_plugin):
		remove_export_plugin(export_plugin)
		export_plugin = null
