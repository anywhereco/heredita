extends VBoxContainer

const GALLERY := preload("res://scenes/main_menu/pages/room_list/new_room/gallery/Gallery.tscn")

var map := ReactiveMapData.new(MapData.read_from_file("assets/map/maps/map.map").val() as MapData)  #eventually this will be an actual Map object
@onready var roomname: LineEdit = %Name


func change_map_texture(_map: ReactiveMapData) -> void:
	%Map.texture = ImageTexture.create_from_image(_map.value.image)


func _ready() -> void:
	roomname.text = tr("roomcreate/name")
	map.value_changed.connect(change_map_texture)
	change_map_texture(map)
	%ChangeMap.pressed.connect(change_map)
	%Create.pressed.connect(create_room)


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
