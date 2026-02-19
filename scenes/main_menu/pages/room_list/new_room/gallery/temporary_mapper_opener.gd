extends Button

@onready var coordinator: ImagePickingCoordinator = %Coordinator
@onready var map_picker: HBoxContainer = $"../../MarginContainer/MapPicker"

func _pressed() -> void:
	const MAPPER_3D = preload("uid://bmfinmmve5h47")
	var mapper: MapperRoot = MAPPER_3D.instantiate()
	map_picker.image.value.convert(Image.FORMAT_RGBA8)
	mapper.find_child("Map").original_map = map_picker.image.value
	get_tree().current_scene.queue_free()
	get_tree().root.add_child(mapper)
	get_tree().current_scene = mapper
