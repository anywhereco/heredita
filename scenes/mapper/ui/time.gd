class_name TimekeepingUI
extends HBoxContainer

static var _inst: TimekeepingUI

@onready var date: Label = $Date
@onready var year: Label = $Year
@onready var calendar: Calendar = Calendar.new(1, 222222)


func _init() -> void:
	_inst = self

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	calendar.process(delta)
	date.text = calendar.date_string()
	year.text = calendar.year_string()

func calendar_sync(details: Dictionary) -> void:
	calendar = Calendar.from_json(details)
