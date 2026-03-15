extends Node

var location := JavaScriptBridge.get_interface("location") if OS.has_feature("web") else null
var params: JavaScriptObject = (
	JavaScriptBridge.create_object("URLSearchParams", location.search)
	if OS.has_feature("web")
	else null
)

enum QueryParamResult { SUCCESSFUL, NO_WEB_ACCESS, PARAMETER_NOT_FOUND }


func get_param(param_name: String) -> Result:
	if not OS.has_feature("web"):
		return Result.err(QueryParamResult.NO_WEB_ACCESS)
	if not params.has(param_name):
		return Result.err(QueryParamResult.PARAMETER_NOT_FOUND)
	return Result.ok(params.get(param_name))
