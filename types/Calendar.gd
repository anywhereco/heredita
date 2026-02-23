extends Node
class_name Calendar

const MPY_TO_SPS = 525600.0 # aka just "How many minutes are in a year"
const SPS_TO_MPY = 1/MPY_TO_SPS

enum Month {
	JANUARY,
	FEBRUARY,
	MARCH,
	APRIL,
	MAY,
	JUNE,
	JULY,
	AUGUST,
	SEPTEMBER,
	OCTOBER,
	NOVEMBER,
	DECEMBER
}

var minutes_per_year: float
var factor: float : 
	get():
		return minutes_per_year * MPY_TO_SPS

var year: int
var month: Month
var day: int

var hour: int
var minute: int
var second: float


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.

@warning_ignore("shadowed_variable")
static func is_leap_year(year: int) -> bool:
	return (year % 4 == 0) and \
		   ((year % 100 != 0) or (year % 400 == 0))

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	second += delta * factor
	
	minute += floor(second / 60)
	second = fmod(second, 60)
	
	@warning_ignore("integer_division")
	hour += minute / 60
	minute %= 60
	
	@warning_ignore("integer_division")
	day += floor(hour / 24)
	hour %= 24
	
