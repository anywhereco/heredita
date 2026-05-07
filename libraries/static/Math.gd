extends Node
class_name Math


static func log10(v: float) -> float:
	return log(v) / log(10)


static func exp10(v: float) -> float:
	return 10.0 ** v
