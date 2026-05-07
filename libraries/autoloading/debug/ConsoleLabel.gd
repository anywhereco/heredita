class_name ConsoleLabel
extends RichTextLabel

var logger := CustomLogger.new()

static var _inst: ConsoleLabel


class CustomLogger:
	extends Logger

	func _log_message(message: String, _error: bool) -> void:
		ConsoleLabel._inst.call_deferred(&"append_text", message)

	func _log_error(
		function: String,
		file: String,
		line: int,
		code: String,
		rationale: String,
		_editor_notify: bool,
		error_type: int,
		script_backtraces: Array[ScriptBacktrace]
	) -> void:
		var prefix: String = ""

		match error_type:
			ERROR_TYPE_ERROR:
				prefix = "[color=#f54][b]ERROR:[/b]"
			ERROR_TYPE_WARNING:
				prefix = "[color=#fd4][b]WARNING:[/b]"
			ERROR_TYPE_SCRIPT:
				prefix = "[color=#f87][b]SCRIPT ERROR:[/b]"
			ERROR_TYPE_SHADER:
				prefix = "[color=#4bf][b]SHADER ERROR:[/b]"

		var trace: String = "at: %s (%s:%s)" % [function, file, line]
		var script_backtraces_text: String = ""
		for backtrace in script_backtraces:
			script_backtraces_text += backtrace.format(3) + "\n"

		(
			ConsoleLabel
			. _inst
			. call_deferred(
				&"append_text",
				(
					"%s %s %s[/color]\n[color=#999]%s[/color]\n[color=#999]%s[/color]"
					% [
						prefix,
						code,
						rationale,
						trace,
						script_backtraces_text,
					]
				)
			)
		)


# Use `_init()` to register the logger as early as possible, which ensures that messages
# printed early are taken into account. However, even when using `_init()`, the engine's own
# initialization messages are not accessible.
func _init() -> void:
	text = ""
	get_v_scroll_bar().mouse_filter = Control.MOUSE_FILTER_PASS
	get_v_scroll_bar().mouse_behavior_recursive = Control.MOUSE_BEHAVIOR_ENABLED
	_inst = self
	OS.add_logger(logger)


# Removing the logger happens automatically when the project exits by default.
# In case you need to remove a custom logger earlier, you can use `OS.remove_logger()`.
# Doing so can also avoid object leak warnings that may be printed on exit.
func _exit_tree() -> void:
	OS.remove_logger(logger)
