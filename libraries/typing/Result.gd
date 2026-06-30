class_name Result

var _return_value: Variant
var _error: int


static func ok(return_value: Variant) -> Result:
	var result := Result.new()
	result._return_value = return_value
	return result


static func err(error: int) -> Result:
	var result := Result.new()
	result._error = error
	return result


func is_err() -> bool:
	return _error != null


func is_ok() -> bool:
	return _return_value != null


func val() -> Variant:
	if is_ok():
		return _return_value
	return null


func err_code() -> Variant:
	if is_err():
		return _error
	return null
