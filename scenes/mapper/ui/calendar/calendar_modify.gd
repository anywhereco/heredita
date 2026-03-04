extends VBoxContainer

@onready var month_edit: LineEdit = $Date/Month
@onready var day_edit: LineEdit = $Date/Day
@onready var year_edit: LineEdit = $Date/Year
@onready var hour_edit: LineEdit = $Time/Hour
@onready var minute_edit: LineEdit = $Time/Minute
@onready var second_edit: LineEdit = $Time/Second
@onready var mpy_edit: LineEdit = $AtMPY/MinutesPerYear

var calendar: Calendar

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	calendar = Calendar.from_json(TimekeepingUI._inst.calendar.to_json())
	month_edit.text = Calendar.Month.keys()[calendar.month].capitalize()
	day_edit.text = Calendar.get_ordinal(calendar.day)
	year_edit.text = calendar.year_string()
	hour_edit.text = "%02d" % calendar.hour
	minute_edit.text = "%02d" % calendar.minute
	second_edit.text = "%02d" % calendar.second
	mpy_edit.text = "%01.5f" % calendar.minutes_per_year
	mpy_edit.text = mpy_edit.text.rstrip("0")
	if mpy_edit.text.ends_with("."):
		mpy_edit.text = mpy_edit.text.rstrip(".")


func _on_cancel_pressed() -> void:
	(get_parent() as PromptInstance).close()
	

func _on_confirm_pressed() -> void:
	_complete.call_deferred()

func _complete() -> void:
	print("sending cal ", calendar.to_json())
	State.client.send("calendar_sync", calendar.to_json())
	TimekeepingUI._inst.calendar = Calendar.from_json(calendar.to_json())
	(get_parent() as PromptInstance).close()

func _on_month_text_submitted(from_unfocus: bool, new_text: String) -> void:
	print(new_text)
	print(month_edit.text)
	if new_text.is_valid_int():
		var monthnumber := new_text.to_int()
		monthnumber -= 1
		if monthnumber < Calendar.Month.MAXIMUM and monthnumber >= 0:
			calendar.month = monthnumber as Calendar.Month
			month_edit.text = Calendar.Month.keys()[monthnumber].capitalize()
			day_edit.grab_focus()
			return
		else:
			month_edit.text = Calendar.Month.keys()[calendar.month].capitalize()
			return
	
	var month := Calendar.str_to_month(new_text)
	if month == Calendar.Month.MAXIMUM:
		month_edit.text = Calendar.Month.keys()[calendar.month].capitalize()
		return
	
	calendar.month = month
	month_edit.text = Calendar.Month.keys()[month].capitalize()
	if not from_unfocus:
		day_edit.grab_focus()
	

func _on_month_editing_toggled(toggled_on: bool) -> void:
	if not toggled_on:
		_on_month_text_submitted(true, month_edit.text)
		return
	month_edit.text = ""

func _on_day_text_submitted(new_text: String, from_unfocus: bool) -> void:
	if not new_text.is_valid_int():
		day_edit.text = Calendar.get_ordinal(calendar.day)
		return
	
	var day := new_text.to_int()
	if day > calendar.days_in_month():
		day_edit.text = Calendar.get_ordinal(calendar.day)
		return
	
	calendar.day = day
	day_edit.text = Calendar.get_ordinal(calendar.day)
	if not from_unfocus:
		year_edit.grab_focus()


func _on_day_editing_toggled(toggled_on: bool) -> void:
	if not toggled_on:
		_on_day_text_submitted(day_edit.text, true)
		return
	day_edit.text = str(calendar.day)


func _on_year_text_submitted(new_text: String, from_unfocus: bool) -> void:
	new_text = new_text.to_lower()
	if new_text.ends_with(" ad"):
		new_text = new_text.substr(0, len(new_text) - 3)
	elif new_text.ends_with(" bc"):
		new_text = "-" + new_text.substr(0, len(new_text) - 3)
	
	if new_text.begins_with("--"): # for "-1500 BC" or similar
		new_text = new_text.substr(1)
	
	if not new_text.is_valid_int():
		year_edit.text = calendar.year_string()
		return
	
	var year := new_text.to_int()
	
	if year > 1_000_000_000:
		year = 1_000_000_000
	if year < -1_000_000_000:
		year = -1_000_000_000
	
	calendar.year = year
	year_edit.text = calendar.year_string()
	if not from_unfocus:
		hour_edit.grab_focus()
	

func _on_year_editing_toggled(toggled_on: bool) -> void:
	if not toggled_on:
		_on_year_text_submitted(year_edit.text, true)
		return
	year_edit.text = str(calendar.year)


func _on_hour_text_submitted(new_text: String, from_unfocus: bool) -> void:
	if not new_text.is_valid_int():
		hour_edit.text = "%02d" % calendar.hour
		return
	
	var hour := new_text.to_int()
	if hour < 0 or hour >= 24:
		hour_edit.text = "%02d" % calendar.hour
		return
	
	calendar.hour = hour
	hour_edit.text = "%02d" % calendar.hour
	if not from_unfocus:
		minute_edit.grab_focus()

func _on_hour_editing_toggled(toggled_on: bool) -> void:
	if not toggled_on:
		_on_hour_text_submitted(hour_edit.text, true)
		return

func _on_minute_text_submitted(new_text: String, from_unfocus: bool) -> void:
	if not new_text.is_valid_int():
		minute_edit.text = "%02d" % calendar.minute
		return
	
	var minute := new_text.to_int()
	if minute < 0 or minute >= 60:
		minute_edit.text = "%02d" % calendar.minute
		return
	
	calendar.minute = minute
	minute_edit.text = "%02d" % calendar.minute
	if not from_unfocus:
		second_edit.grab_focus()


func _on_minute_editing_toggled(toggled_on: bool) -> void:
	if not toggled_on:
		_on_minute_text_submitted(minute_edit.text, true)
		return


func _on_second_text_submitted(new_text: String, from_unfocus: bool) -> void:
	if not new_text.is_valid_int():
		second_edit.text = "%02d" % calendar.second
		return
	
	var second := new_text.to_int()
	if second < 0 or second >= 60:
		second_edit.text = "%02d" % calendar.second
		return
	
	calendar.second = second
	second_edit.text = "%02d" % calendar.second
	if not from_unfocus:
		mpy_edit.grab_focus()

func _on_second_editing_toggled(toggled_on: bool) -> void:
	if not toggled_on:
		_on_second_text_submitted(second_edit.text, true)
		return


func _on_minutes_per_year_text_submitted(new_text: String, _from_unfocus: bool) -> void:
	if not new_text.is_valid_float():
		mpy_edit.text = "%01.5f" % calendar.minutes_per_year
		mpy_edit.text = mpy_edit.text.rstrip("0")
		if mpy_edit.text.ends_with("."):
			mpy_edit.text = mpy_edit.text.rstrip(".")
		return
	
	var mpy := new_text.to_float()

	if mpy < 0:
		mpy_edit.text = "%01.5f" % calendar.minutes_per_year
		mpy_edit.text = mpy_edit.text.rstrip("0")
		if mpy_edit.text.ends_with("."):
			mpy_edit.text = mpy_edit.text.rstrip(".")
		return
	if mpy < Calendar.MIN_MPY:
		mpy = Calendar.MIN_MPY
	
	calendar.minutes_per_year = mpy
	mpy_edit.text = "%01.5f" % calendar.minutes_per_year
	mpy_edit.text = mpy_edit.text.rstrip("0")
	if mpy_edit.text.ends_with("."):
		mpy_edit.text = mpy_edit.text.rstrip(".")


func _on_minutes_per_year_editing_toggled(toggled_on: bool) -> void:
	pass # Replace with function body.
	
	if not toggled_on:
		_on_minutes_per_year_text_submitted(mpy_edit.text, true)
		return
