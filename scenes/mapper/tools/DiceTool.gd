class_name DiceTool
extends Resource

var min_roll: int = 1
var max_roll: int = 6

func _init() -> void:
	pass

func dice_events(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		if State.client:
			State.client.send("dice", {"max": max_roll, "min": min_roll})

func display_result(result: String) -> void:
	pass
