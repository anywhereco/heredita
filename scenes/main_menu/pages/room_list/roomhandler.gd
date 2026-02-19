class_name RoomHandler 
extends VBoxContainer

@onready var loading_placeholder: CenterContainer = $LoadingPlaceholder
@onready var create: HBoxContainer = $Create
var loading_placeholder_text: String

static var _instance: RoomHandler

func _ready() -> void:
	_instance = self
	loading_placeholder_text = loading_placeholder.get_node("Label").text
	_load_rooms()

func _process(_delta: float) -> void:
	pass

func _load_rooms() -> void:
	loading_placeholder.show()
	loading_placeholder.get_node("Label").text = loading_placeholder_text

	var children := get_children()
	for i in range(1, children.size() - 1): # Exclude the first since that's a loading indicator, and the last since that's the creation buttons
		var child_to_delete := children[i]
		child_to_delete.queue_free()
		
	var rooms := await HTTP.request(Statics.HEREDITA_URL, "rooms")
	# TODO error check!!
	if rooms.is_err():
		match rooms.err_code():
			HTTP.HTTPResult.FAILED_REQUEST:
				loading_placeholder.get_node("Label").text = "Could not reach server. Try again later."
				return
	for room_id: String in rooms.val():
		var room: Dictionary = rooms.val()[room_id]
		add_child(RoomTemplate.of(
			self,
			room_id,
			room["name"] as String,
			room["description"] as String,
			room["player_count"] as int,
			room["player_limit"] as int
		))
	move_child(create, -1)
	loading_placeholder.hide()

func enter_mapper(map: PackedByteArray = PackedByteArray()) -> void:
	const MAPPER_3D = preload("uid://bmfinmmve5h47")
	var mapper: MapperRoot = MAPPER_3D.instantiate()
	if map:
		Map._instance.deserialize(map)
	get_tree().current_scene.queue_free()
	get_tree().root.add_child(mapper)
	get_tree().current_scene = mapper
	VirtualMouse._instance.enabled = true

func join_room(_id: String, creation: Dictionary = {}, map: PackedByteArray = PackedByteArray()) -> void:
	if creation:
		assert(map, "Attempted to create room with no map")
		State.client = InfernoSocketClient.new(Statics.SERVER_URL, 0, creation, map)
	else:
		State.client = InfernoSocketClient.new(Statics.SERVER_URL, int(_id))
	get_tree().root.add_child(State.client)
	State.client.handshake_complete.connect(enter_mapper.bind(map))
