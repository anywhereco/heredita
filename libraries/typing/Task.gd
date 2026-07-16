class_name Task
extends RefCounted

var function: Callable
## In microseconds.
var delay: int
## In microseconds.
var timestamp_of_next_call: int


func _init(fn: Callable, _delay: float, call_immediately: bool = false) -> void:
	function = fn
	delay = int(_delay * 1_000_000)
	timestamp_of_next_call = Time.get_ticks_usec() + (0 if call_immediately else delay)


## Note that depending on the delay, this may call the function multiple times.
func poll() -> void:
	while Time.get_ticks_usec() > timestamp_of_next_call:
		timestamp_of_next_call += delay
		function.call()


func should_call() -> bool:
	return Time.get_ticks_usec() > timestamp_of_next_call
