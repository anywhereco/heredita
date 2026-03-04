class_name DiceTool
extends Resource

var min_roll: int = 1
var max_roll: int = 6

func _init() -> void:
	if State.client:
		pass

func dice_events(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		var settings: Dictionary = {"max": max_roll, "min": min_roll}
		if State.client:
			State.client.send("dice", settings)
		else:
			display_result(roll(settings))

static func roll(settings: Dictionary) -> DiceResult: #only used by SERVER if not in singleplayer
	return DiceResult.new(randi_range(settings.get("min", 1), settings.get("max", 20)))

func display_result(result: DiceResult) -> void:
	pass
