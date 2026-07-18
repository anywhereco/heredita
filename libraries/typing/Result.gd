class_name Result

var _return_value: Variant
var _error: int
var _is_ok: bool

static func ok(return_value: Variant) -> Result:
	var result := Result.new()
	result._return_value = return_value
	result._is_ok = true
	return result
	

static func err(error: int) -> Result:
	var result := Result.new()
	result._error = error
	result._is_ok = false
	return result


func is_err() -> bool:
	return not _is_ok


func is_ok() -> bool:
	return _is_ok


func val() -> Variant:
	if is_ok():
		return _return_value
	return null


func err_code() -> Variant:
	if is_err():
		return _error
	return null
