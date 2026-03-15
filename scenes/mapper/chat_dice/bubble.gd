class_name ChatBubble
extends MeshInstance3D

signal fading

const BUBBLE_ASCENSION = 1.7
const BUBBLE_EXTRA_ASCENSION = -0.27  #negative because Bubble2
const BUBBLE_FADE = 0.8  #fade of older bubbles
const MAX_AGE = 10.0

var text: String
@onready var Text: Label = find_child("Text")
@onready var Bubble2D: Control = find_child("Bubble2D")
@onready var BubbleTail: TextureRect = find_child("BubbleTail")

var fade_curve: Curve = preload("res://scenes/mapper/chat_dice/bubble_fade_curve.tres")

var age := 0.0
var bubble_position := 0  #increases if this bubble is supplanted by another bubble
var root_position := Vector3.ZERO
var position_offset := 0.0  #calculated by player object


static func create(_text: String) -> ChatBubble:
	var bubble := preload("res://scenes/mapper/chat_dice/bubble.tscn").instantiate()
	bubble.text = _text
	return bubble


func get_height() -> float:
	return Bubble2D.size.y / $BubbleViewport.size.y * scale.y


func update_position() -> void:
	var up: Vector3 = get_viewport().get_camera_3d().global_transform.basis.y
	position = root_position
	position += up * position_offset


func _ready() -> void:
	Text.text = text


func _process(delta: float) -> void:
	age += delta
	if age > MAX_AGE:
		queue_free()
		fading.emit()
		return
	mesh.surface_get_material(0).albedo_color.a = (
		fade_curve.sample(age) * BUBBLE_FADE ** bubble_position
	)
	update_position()
	if BubbleTail.visible and bubble_position > 0:
		BubbleTail.hide()
