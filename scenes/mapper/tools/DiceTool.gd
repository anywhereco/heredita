class_name DiceTool
extends Resource

const COOLDOWN: float = 0.5

var min_roll: int = 1
var max_roll: int = 6
var cooldown: float = 0

func _init() -> void:
	if State.client:
		State.client.message_received.connect(message_received)

func _map_ready() -> void:
	UIRoot._instance.dice_ui.size_controller.value_changed.connect(_size_changed.unbind(1))
	_size_changed()

func _size_changed() -> void:
	max_roll = UIRoot._instance.dice_ui.size_controller.value

func dice_events(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		if cooldown > 0:
			return
		var settings: Dictionary = {"max": max_roll, "min": min_roll}
		var position_2: Vector2 = MapperRoot._instance.get_node("LocalPlayer").mouse_pos_on_map()
		var position: Vector3 = Vector3(position_2.x, DiceBubble.HOVER, position_2.y)
		if State.client:
			State.client.send("dice", {"position": ISUtil.from_vec3(position), "settings": settings})
			cooldown = COOLDOWN
		else:
			display_result(MapperRoot._instance.get_node("LocalPlayer").position as Vector3, -2, roll(settings))
			
func message_received(event: String, player_id: int, details: Variant) -> void:
	if event == "dice_result" and player_id == -1:
		display_result(ISUtil.to_vec3(details["position"]), details["player_id"], DiceResult.from_data(details["result"] as Dictionary))

func display_result(position: Vector3, player_id: int, result: DiceResult) -> void:
	var result_string: String
	if result["outcome"] is float:
		result_string = str(int(result["outcome"]))
	elif result["outcome"] is Array:
		pass #this doesnt happen yet so we dont have to deal with it
	var roller: String
	if State.client:
		roller = "%s rolled" % State.room.players.getv(player_id).username
	else:
		roller = ""
	var dice_bubble := DiceBubble.create(result["die_string"] as String, result_string, roller)
	MapperRoot._instance.add_child(dice_bubble)
	dice_bubble.position = position

static func roll(settings: Dictionary) -> DiceResult: #only used by SERVER if not in singleplayer
	var die_string: String
	if settings["min"] == 1:
		die_string = "d%d" % settings["max"]
	else:
		die_string = "%d⋯%d" % [settings["min"], settings["max"]]
	return DiceResult.new(randi_range(settings.get("min", 1) as int, settings.get("max", 20) as int), die_string)

func _process(delta: float) -> void:
	cooldown = maxf(0.0, cooldown-delta)
