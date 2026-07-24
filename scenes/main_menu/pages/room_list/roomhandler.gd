class_name RoomHandler
extends VBoxContainer

const MAPPER_3D_PATH := "res://scenes/mapper/mapper3d.tscn"

@onready var loading_placeholder: CenterContainer = $LoadingPlaceholder
@onready var loading_placeholder_label: Label = $LoadingPlaceholder/Label
@onready var create: HBoxContainer = $Create
var loading_placeholder_text: String

static var _instance: RoomHandler

var _game_loading := false
var _mapper_load_started := false
var _game_load_finishing := false
var _game_load_detail := ""
var _game_load_progress: Array = []
var _pending_map: MapData
var _loading_prompt: PromptInstance
var _loading_prompt_spinner: Spinner
var _loading_prompt_label: Label

var _game_load_time: float = 0.0
var _buffered_map_data: PackedByteArray = PackedByteArray()
var _mapper_ready := false

const LOAD_TIMEOUT: float = 30.0


func _ready() -> void:
	_instance = self
	loading_placeholder_text = loading_placeholder_label.text
	_load_rooms()


func _process(delta: float) -> void:
	if _game_loading:
		_update_game_loading(delta)


func _load_rooms() -> void:
	if _game_loading:
		return
	loading_placeholder.show()
	loading_placeholder_label.text = loading_placeholder_text

	var children := get_children()
	for i in range(1, children.size() - 1):  # Exclude the first since that's a loading indicator, and the last since that's the creation buttons
		var child_to_delete := children[i]
		child_to_delete.queue_free()
	
	var rooms := await HTTP.request(Statics.HEREDITA_URL, "rooms", HTTPClient.METHOD_GET, State.user.token)
	# TODO error check!!
	if rooms.is_err():
		match rooms.err_code():
			HTTP.HTTPResult.FAILED_REQUEST:
				loading_placeholder_label.text = tr("roomlist/loading.failed")
				return
	elif rooms.val().is_empty():
		loading_placeholder_label.text = tr("roomlist/loading.empty")
		return
	for room_id: String in rooms.val():
		var room: Dictionary = rooms.val()[room_id]
		var friends: Array[Player]
		for friend: Dictionary in room.get("friends", []):
			friends.append(Player.from_info(friend))
		add_child(
			RoomTemplate.of(
				self,
				room_id,
				room["name"] as String,
				room["description"] as String,
				room["player_count"] as int,
				room["player_limit"] as int,
				friends
			)
		)
	move_child(create, -1)
	loading_placeholder.hide()


func enter_mapper(map: MapData = null) -> void:
	if _mapper_load_started:
		return
	_pending_map = map
	_buffered_map_data.clear()
	_mapper_load_started = true
	_game_load_finishing = false
	_game_load_time = 0.0
	_game_load_progress.clear()
	_set_game_load_detail("Preparing mapper...")

	var err := ResourceLoader.load_threaded_request(MAPPER_3D_PATH, "PackedScene", false)
	if err != OK:
		_fail_game_load("Could not start loading the mapper.")


func _update_game_loading(delta: float) -> void:
	if not _mapper_load_started:
		return

	_game_load_time += delta
	if _game_load_time > LOAD_TIMEOUT:
		_fail_game_load("Loading timed out.")
		return

	if not _game_load_finishing:
		var status := ResourceLoader.load_threaded_get_status(
			MAPPER_3D_PATH,
			_game_load_progress
		)
		match status:
			ResourceLoader.THREAD_LOAD_IN_PROGRESS:
				var percent := 0
				if not _game_load_progress.is_empty():
					percent = roundi((_game_load_progress[0] as float) * 100.0)
					_set_spinner_progress(percent)
				_game_load_detail = "Loading mapper resources... %d%%" % percent
			ResourceLoader.THREAD_LOAD_LOADED:
				_game_load_finishing = true
				_set_spinner_indeterminate()
				_game_load_detail = "Starting mapper..."
				_finish_mapper_load.call_deferred()
			ResourceLoader.THREAD_LOAD_FAILED:
				_fail_game_load("Could not load the mapper.")
				return
			ResourceLoader.THREAD_LOAD_INVALID_RESOURCE:
				_fail_game_load("Could not find the mapper scene.")
				return

	_set_game_loading_text()


func _set_game_loading_text() -> void:
	if is_instance_valid(_loading_prompt_label):
		_loading_prompt_label.text = _game_load_detail
	else:
		loading_placeholder_label.text = _game_load_detail


func _finish_mapper_load() -> void:
	var mapper_scene := ResourceLoader.load_threaded_get(MAPPER_3D_PATH) as PackedScene
	if mapper_scene == null:
		_fail_game_load("Could not load the mapper.")
		return
	var mapper := mapper_scene.instantiate() as MapperRoot
	if mapper == null:
		_fail_game_load("Could not create the mapper.")
		return
	_close_game_loading_prompt()
	if not _buffered_map_data.is_empty():
		Map._instance.set_data(MapData.deserialize(_buffered_map_data))
		Map._instance.finish_resync()
	elif _pending_map != null:
		Map._instance.set_data(_pending_map)
	if get_tree().current_scene != null:
		get_tree().current_scene.queue_free()
	get_tree().root.add_child(mapper)
	get_tree().current_scene = mapper
	_mapper_ready = true


func _fail_game_load(message: String) -> void:
	_game_loading = false
	_mapper_load_started = false
	_game_load_finishing = false
	_pending_map = null
	_close_game_loading_prompt()
	loading_placeholder.show()
	loading_placeholder_label.text = message


func _begin_game_loading(message: String) -> void:
	_game_loading = true
	_mapper_load_started = false
	_game_load_finishing = false
	_game_load_progress.clear()
	_show_game_loading_prompt()
	_set_spinner_indeterminate()
	_set_game_load_detail(message)


func _show_game_loading_prompt() -> void:
	if is_instance_valid(_loading_prompt):
		return
	var prompt_res := Prompts.new_fullscreen_prompt()
	if prompt_res.is_err():
		loading_placeholder.show()
		return
	_loading_prompt = prompt_res.val()
	_loading_prompt.make_uncloseable()

	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 20)
	margin.add_theme_constant_override("margin_top", 16)
	margin.add_theme_constant_override("margin_right", 20)
	margin.add_theme_constant_override("margin_bottom", 16)

	var content := VBoxContainer.new()
	content.alignment = BoxContainer.ALIGNMENT_CENTER
	content.add_theme_constant_override("separation", 12)

	_loading_prompt_spinner = Spinner.new()
	_loading_prompt_spinner.custom_minimum_size = Vector2(48, 48)
	_loading_prompt_spinner.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	_loading_prompt_spinner.status = Spinner.Status.SPINNING

	_loading_prompt_label = Label.new()
	_loading_prompt_label.custom_minimum_size = Vector2(280, 0)
	_loading_prompt_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_loading_prompt_label.text = "Loading..."
	_loading_prompt_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART

	content.add_child(_loading_prompt_spinner)
	content.add_child(_loading_prompt_label)
	margin.add_child(content)
	_loading_prompt.add_child(margin)


func _close_game_loading_prompt() -> void:
	if is_instance_valid(_loading_prompt):
		Prompts.close_prompt(_loading_prompt.idx)
	_loading_prompt = null
	_loading_prompt_spinner = null
	_loading_prompt_label = null


func _set_spinner_indeterminate() -> void:
	if not is_instance_valid(_loading_prompt_spinner):
		return
	_loading_prompt_spinner.status = Spinner.Status.SPINNING


func _set_spinner_progress(percent: int) -> void:
	if not is_instance_valid(_loading_prompt_spinner):
		return
	_loading_prompt_spinner.min_value = 0
	_loading_prompt_spinner.max_value = 100
	_loading_prompt_spinner.set_progressing(percent)


func _set_game_load_detail(message: String) -> void:
	_game_load_detail = message
	_set_game_loading_text()


func _client_loading_status_updated(details: Dictionary) -> void:
	var message := details.get("message", "") as String
	if message.is_empty():
		return
	if details.get("failed", false):
		_fail_game_load(message)
		return
	if details.has("map_size"):
		var map_size_kb := ceili((details["map_size"] as int) / 1024.0)
		message = "%s (%d KiB)" % [message, map_size_kb]
	_set_game_load_detail(message)


func join_room(_id: String, creation: Dictionary = {}, map: MapData = null) -> void:
	if _game_loading:
		return
	_begin_game_loading("Connecting to game server...")
	if creation:
		assert(map != null, "Attempted to create room with no map")
		State.client = InfernoSocketClient.new(Statics.SERVER_URL, 0, creation, map.serialize())
	else:
		State.client = InfernoSocketClient.new(Statics.SERVER_URL, int(_id))
	State.client.connected_to_server.connect(
		_set_game_load_detail.bind("Connected. Waiting for handshake...")
	)
	State.client.loading_status_updated.connect(_client_loading_status_updated)
	State.client.connection_closed.connect(premature_close)
	State.client.handshake_complete.connect(enter_mapper.bind(map))
	State.client.binary_message_received.connect(_buffer_binary_data)
	get_tree().root.add_child(State.client)


func _buffer_binary_data(event: int, _player_id: int, _flags: int, details: PackedByteArray) -> void:
	if event != ISUtil.BinaryEvents.SYNC_MAP or _mapper_ready:
		return
	_buffered_map_data = details


func premature_close() -> void:
	var reason := State.client.socket.get_close_code()
	var reason_text := State.client.socket.get_close_reason()
	print("Failed to join room: %d" % reason)
	if _game_loading and not _mapper_load_started:
		var message := "Failed to join room: %d" % reason
		if not reason_text.is_empty():
			message = "%s (%s)" % [message, reason_text]
		_fail_game_load(message)
