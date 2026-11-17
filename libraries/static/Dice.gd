class_name Dice
extends RefCounted


static func roll(settings: Dictionary) -> DiceResult:
	var die_string: String
	if settings["min"] == 1:
		die_string = "d%d" % settings["max"]
	else:
		die_string = "%d⋯%d" % [settings["min"], settings["max"]]
	return DiceResult.new(
		randi_range(settings.get("min", 1) as int, settings.get("max", 20) as int), die_string
	)
