extends VBoxContainer

const GALLERY := preload("res://scenes/main_menu/pages/room_list/new_room/gallery/Gallery.tscn")

## When the gallery is made, *the same mapdata* is sent to it!!
#eventually this will be an actual Map object
var map := ReactiveMapData.new(MapData.read_from_file("assets/map/maps/map.map").val() as MapData)
var _image: Image = null
@onready var roomname: LineEdit = %Name


func change_map_data(_map: ReactiveMapData) -> void:
	if _image != map.value.image:
		%Map.texture = ImageTexture.create_from_image(_map.value.image)
	%Map.texture = ImageTexture.create_from_image(_map.value.image)


func _ready() -> void:
	roomname.text = tr("roomcreate/name")
	map.value_changed.connect(change_map_data)
	change_map_data(map)
	%ChangeMap.pressed.connect(change_map)
	%Create.pressed.connect(create_room)
	@warning_ignore("unsafe_call_argument")
	var ppu := find_child("PPUValue", true, false)
	if ppu != null:
		ppu.setup(map)


func change_map() -> void:
	var prompt_res := Prompts.new_fullscreen_prompt()
	if prompt_res.is_err():
		return
	hide()
	var prompt: PromptInstance = prompt_res.val()
	var gallery := GALLERY.instantiate()
	gallery.find_child("MapPickerButton").map = map
	prompt.prompt_closed.connect(show)
	prompt.add_child(gallery)


func create_room() -> void:
	var create_dict: Dictionary = {}
	if not %Name.text:
		InfoPrompt.prompt("Cannot create a room with an empty name!")
		return
	create_dict["name"] = %Name.text
	create_dict["description"] = %Description.text
	create_dict["password"] = %Password.text
	create_dict["player_cap"] = %PlayerCap.value
	var map_object := map.value
	var prompt := Prompts.get_prompt_in(self)
	if prompt != null:
		Prompts.close_prompt(prompt.idx)
	RoomHandler._instance.join_room("", create_dict, map_object)
