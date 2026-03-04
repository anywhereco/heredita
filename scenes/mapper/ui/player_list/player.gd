class_name PlayerListElement
extends MarginContainer

@onready var elements: HBoxContainer = $Elements

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta: float) -> void:
	pass


func add_badge(texture: Texture2D) -> TextureRect:
	var texturerect := TextureRect.new()
	texturerect.texture = texture
	texturerect.expand_mode = TextureRect.EXPAND_FIT_WIDTH
	elements.add_child(texturerect)
	elements.move_child(texturerect, 0)

	return texturerect
