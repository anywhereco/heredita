class_name Promise

signal done(output: Array)


func emit(...args: Array) -> void:
	done.emit(args)


func _init(...signals: Array) -> void:
	#done() will be emitted when receiving any signal.
	for sig: Signal in signals:
		sig.connect(emit)
