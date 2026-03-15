class_name TimekeepingUI
extends HBoxContainer

static var _inst: TimekeepingUI

@onready var pause: Button = $PauseMargin/Pause
@onready var configure: Button = $ConfMargin/Configure

@onready var date: Label = $TimeInner/Date
@onready var year: Label = $TimeInner/Year
@onready var time: Label = $TimeInner/Time

var calendar: Calendar = Calendar.new(1, 222222)

const PAUSE_IMG = preload("uid://5530a3jumjn0")
const PLAY_IMG = preload("uid://bnp8cynxn3io4")

const CALENDAR_MODIFY = preload("uid://o1ehxmubcjv8")


func _init() -> void:
	_inst = self


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	if not State.player.privileged():
		pause.hide()
		configure.hide()


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	calendar.process(delta)
	date.text = calendar.date_string()
	year.text = calendar.year_string()
	time.text = calendar.time_string()


func calendar_sync(details: Dictionary) -> void:
	calendar = Calendar.from_json(details)


func _on_pause_pressed() -> void:
	if not State.player.privileged():
		return

	calendar.paused = not calendar.paused

	if calendar.paused:
		pause.icon = PLAY_IMG
	else:
		pause.icon = PAUSE_IMG

	State.client.send("calendar_sync", calendar.to_json())


func _on_configure_pressed() -> void:
	if not State.player.privileged():
		return

	var promptres := Prompts.new_fullscreen_prompt()
	if promptres.is_err():
		return
	var prompt: PromptInstance = promptres.val()

	var ui := CALENDAR_MODIFY.instantiate()

	prompt.add_child(ui)
