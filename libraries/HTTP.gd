extends Node

enum HTTPResult { SUCCESSFUL, INVALID, FAILED_REQUEST, BAD_RESPONSE }


func _create_url(
	domain: String, endpoint: String, parameters: Dictionary[String, Variant]
) -> String:
	if not domain.begins_with("http"):
		domain = "https://" + domain
	if not endpoint.ends_with("/"):
		endpoint += "/"
	var url := domain + "/" + endpoint
	var query_string := ""
	for key in parameters:
		if query_string.is_empty():
			query_string += ("?" + key.uri_encode() + "=" + str(parameters[key]).uri_encode())
		else:
			query_string += ("&" + key.uri_encode() + "=" + str(parameters[key]).uri_encode())
	return url + query_string


func request(
	domain: String,
	endpoint: String,
	method: HTTPClient.Method = HTTPClient.METHOD_GET,
	auth: String = "",
	query_params: Dictionary[String, Variant] = {},
	response_body_required: bool = true
) -> Result:
	var req := HTTPRequest.new()
	add_child(req)
	req.request_completed.connect(req.queue_free.unbind(4))

	var url := _create_url(domain, endpoint, query_params)

	var error := OK
	if auth:
		error = req.request(url, ["Authorization: Bearer " + auth], method)
	else:
		error = req.request(url, [], method)

	if error != OK:
		return Result.err(HTTPResult.INVALID)

	var request_outcome: Array = await req.request_completed

	var result: int = request_outcome[0]
	var _response_code: int = request_outcome[1]
	var _headers: PackedStringArray = request_outcome[2]
	var body: PackedByteArray = request_outcome[3]

	if result != HTTPRequest.RESULT_SUCCESS:
		return Result.err(HTTPResult.FAILED_REQUEST)

	var json := JSON.new()
	json.parse(body.get_string_from_utf8())
	var response: Variant = json.get_data()

	if response == null and response_body_required:
		return Result.err(HTTPResult.BAD_RESPONSE)

	return Result.ok(response)
