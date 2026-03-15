extends VBoxContainer

const GALLERY := preload("res://scenes/main_menu/pages/room_list/new_room/gallery/Gallery.tscn")

var map := ReactiveImage.new(preload("uid://do2qcumlvx0lo"))  #eventually this will be an actual Map object


func change_map_texture(_map: ReactiveImage) -> void:
	$CenterContainer/Map.texture = ImageTexture.create_from_image(map.value)


func _ready() -> void:
	map.value_changed.connect(change_map_texture)
	change_map_texture(map)
	$ChangeMap.pressed.connect(change_map)
	$Buttons/Create.pressed.connect(create_room)


func change_map() -> void:
	var prompt_res := Prompts.new_fullscreen_prompt()
	if prompt_res.is_err():
		return
	var prompt: PromptInstance = prompt_res.val()
	var gallery := GALLERY.instantiate()
	gallery.find_child("ImagePickerButton").image = map
	prompt.add_child(gallery)


func create_room() -> void:
	var create_dict: Dictionary = {}
	if not $Name.text:
		InfoPrompt.prompt("Cannot create a room with an empty name!")
		return
	create_dict["name"] = $Name.text
	create_dict["description"] = $Description.text
	create_dict["password"] = $Password.text
	create_dict["player_cap"] = $PlayerCapBox/PlayerCap.value
	var map_object := MapData.new()
	map_object.image = map.value
	loading_prompt()
	RoomHandler._instance.join_room("", create_dict, map_object)


func loading_prompt() -> void:
	var prompt_res := Prompts.new_fullscreen_prompt()
	if prompt_res.is_err():
		return
	var prompt: PromptInstance = prompt_res.val()
	var loading_label := Label.new()
	loading_label.text = "Loading..."
	prompt.add_child(loading_label)
	prompt.make_uncloseable()
