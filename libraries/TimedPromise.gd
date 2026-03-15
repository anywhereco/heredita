extends Promise
class_name TimedPromise


func _init(timer: SceneTreeTimer, ...signals: Array) -> void:
	#Time is specified in milliseconds.
	timer.timeout.connect(emit)
	for sig: Signal in signals:
		sig.connect(emit)
