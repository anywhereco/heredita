class_name DiceBubble
extends MeshInstance3D

const HOVER = 1.2
const MAX_AGE = 10.0

var die_string: String
var outcome: String
var roller: String
@onready var DieString: Label = find_child("DieString")
@onready var Outcome: Label = find_child("Outcome")
@onready var Roller: Label = find_child("Roller")

var fade_curve: Curve = preload("res://scenes/mapper/chat_dice/bubble_fade_curve.tres")

var age := 0.0

static func create(_die_string: String, _outcome: String, _roller: String) -> DiceBubble:
	var bubble := preload("res://scenes/mapper/chat_dice/dice_bubble.tscn").instantiate()
	bubble.die_string = _die_string
	bubble.outcome = _outcome
	bubble.roller = _roller
	return bubble

func _ready() -> void:
	DieString.text = die_string
	Outcome.text = outcome
	Roller.text = roller

func _process(delta: float) -> void:
	age += delta
	if age > MAX_AGE:
		queue_free()
		return
	mesh.surface_get_material(0).albedo_color.a = fade_curve.sample(age)
