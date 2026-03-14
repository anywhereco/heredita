extends Resource
class_name Calendar

const MPY_TO_SPS = 525600.0 # aka just "How many minutes are in a year"
const SPS_TO_MPY = 1/MPY_TO_SPS

const YEARS_IN_CYCLE = 400
const DAYS_IN_CYCLE = 146097 # 303 non leap years and 97 leap years

const MIN_MPY = 0.0005

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
	DECEMBER,
	MAXIMUM
}

var minutes_per_year: float
var factor: float : 
	get():
		return MPY_TO_SPS / minutes_per_year

var year: int
var month: Month
var day: int

var hour: int
var minute: int
var second: float

var paused: bool

func _init(mpy: float, _year: int) -> void:
	minutes_per_year = maxf(mpy, MIN_MPY)
	year = _year
	month = Month.JANUARY
	day = 1
	hour = 0
	minute = 0
	second = 0
	paused = false

## Same as the regular function, but in the case of failure throws a null
static func from_json_safe(json: Dictionary) -> Calendar:
	if typeof(json["minutes_per_year"]) != TYPE_FLOAT or\
	   typeof(json["year"]) not in [TYPE_FLOAT, TYPE_INT] or\
	   typeof(json["month"]) not in [TYPE_FLOAT, TYPE_INT] or\
	   typeof(json["day"]) not in [TYPE_FLOAT, TYPE_INT] or\
	   typeof(json["hour"]) not in [TYPE_FLOAT, TYPE_INT] or\
	   typeof(json["minute"]) not in [TYPE_FLOAT, TYPE_INT] or\
	   typeof(json["second"]) != TYPE_FLOAT or\
	   typeof(json["paused"]) != TYPE_BOOL:
		return null
	return from_json(json)

static func from_json(json: Dictionary) -> Calendar:
	var inst := new(0, 0)
	@warning_ignore("unsafe_call_argument")
	inst.minutes_per_year = maxf(json["minutes_per_year"], MIN_MPY)
	inst.year = json["year"]
	inst.month = json["month"]
	inst.day = json["day"]
	inst.hour = json["hour"]
	inst.minute = json["minute"]
	inst.second = json["second"]
	inst.paused = json["paused"]
	return inst

@warning_ignore("shadowed_variable")
static func is_leap_year(year: int) -> bool:
	return (year % 4 == 0) and \
		   ((year % 100 != 0) or (year % 400 == 0))
		
static func get_ordinal(number: int) -> String:
	var last_digit: int = number % 10
	var last_pair: int = number % 100

	if last_digit == 1 and last_pair != 11:
		return str(number) + "st"
	if last_digit == 2 and last_pair != 12:
		return str(number) + "nd"
	if last_digit == 3 and last_pair != 13:
		return str(number) + "rd"
	return str(number) + "th"

@warning_ignore("shadowed_variable")
static func days_in_month_static(month: Month, year: int) -> int:
	match month:
		Month.JANUARY: return 31
		Month.FEBRUARY: return 29 if is_leap_year(year) else 28
		Month.MARCH: return 31
		Month.APRIL: return 30
		Month.MAY: return 31
		Month.JUNE: return 30
		Month.JULY: return 31 
		Month.AUGUST: return 31
		Month.SEPTEMBER: return 30
		Month.OCTOBER: return 31
		Month.NOVEMBER: return 30
		Month.DECEMBER: return 31
		_: 
			push_error("month %d doesn't have a set amount of days waaaa" % month)
			return 0

## Returns Month.MAXIMUM if no valid month could be determined
static func str_to_month(string: String) -> Month:
	match string.to_lower():
		"jan", "january":
			return Month.JANUARY
		"feb", "febuary", "february": # epic anti-tpyo prevention
			return Month.FEBRUARY
		"mar", "march":
			return Month.MARCH
		"apr", "april":
			return Month.APRIL
		"may":
			return Month.MAY
		"jun", "june":
			return Month.JUNE
		"jul", "july":
			return Month.JULY
		"aug", "august":
			return Month.AUGUST
		"sep", "september":
			return Month.SEPTEMBER
		"oct", "october":
			return Month.OCTOBER
		"nov", "november":
			return Month.NOVEMBER
		"dec", "december":
			return Month.DECEMBER
		_:
			return Month.MAXIMUM

func days_in_month() -> int:
	return days_in_month_static(month, year)
		
func process(delta: float) -> void:
	if paused:
		return
	
	second += delta * factor
	
	minute += floor(second / 60)
	second = fmod(second, 60)
	
	@warning_ignore("integer_division")
	hour += minute / 60
	minute %= 60
	
	@warning_ignore("integer_division")
	day += floor(hour / 24)
	hour %= 24
	
	var days_in_year := 366 if is_leap_year(year) else 365
	
	if day > DAYS_IN_CYCLE:
		@warning_ignore("integer_division")
		var cycles := floori(day / DAYS_IN_CYCLE)
		day %= DAYS_IN_CYCLE 
		year += YEARS_IN_CYCLE * cycles
	
	if day > days_in_year:
		day -= days_in_year
		year += 1
		if year == 0:
			year = 1
		days_in_year = 366 if is_leap_year(year) else 365
	
	while day > days_in_month():
		day -= days_in_month()
		
		@warning_ignore("int_as_enum_without_cast")
		month += 1
		
		if month == Month.MAXIMUM:
			month = 0 as Month
			
		if month == 0:
			year += 1
			if year == 0:
				year = 1

func date_string() -> String:
	var month_str: String = Month.keys()[month]
	month_str = month_str.to_lower().capitalize()
	return month_str + " " + get_ordinal(day)

func year_string() -> String:
	if year < 0:
		return str(-year) + " BC"
	elif year < 1500:
		return str(year) + " AD"
	return str(year)

func time_string() -> String:
	if Settings.getv("enable_seconds", true):
		return "%02d:%02d:%02d" % [hour, minute, second]
	else:
		return "%02d:%02d" % [hour, minute]

func to_json() -> Dictionary:
	return {
		"minutes_per_year": minutes_per_year,
		"year": year,
		"month": month,
		"day": day,
		"hour": hour,
		"minute": minute,
		"second": second,
		"paused": paused
	}

func _to_string() -> String:
	return "Calendar%s" % to_json()
