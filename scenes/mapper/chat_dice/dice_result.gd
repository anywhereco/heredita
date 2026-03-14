class_name DiceResult
extends Node

var outcome: Variant
var die_string: String

func _init(_outcome: Variant, _die_string: String) -> void:
	outcome = _outcome
	die_string = _die_string

func to_data() -> Dictionary:
	return {"outcome": outcome, "die_string": die_string}

static func from_data(dict: Dictionary) -> DiceResult:
	return DiceResult.new(dict["outcome"], str(dict["die_string"]))
