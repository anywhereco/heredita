extends Resource
class_name PrimaryUser

signal ready_to_initialize()
signal user_initialized()
signal failed(response_code: int)

var initialized: bool = false

var token: String
var id: int
var username: String
## Will be empty if there is no email.
var email: String
var friends: Array[UserPartial]
var friend_requests_sent: Array[UserPartial]
var friend_requests_received: Array[UserPartial]

var http: HTTPRequest

func _init(_http: HTTPRequest = null, _token: String = "<no token>") -> void:
	token = _token
	http = _http

func signup(_username: String, password: String, _email: String) -> void:
	http.request_completed.connect(_signup_complete.bind(_username, password))
	if _email != null and _email != "":
		_email = "&email=" + _email
	else:
		_email = ""
	http.request(
		Statics.HEREDITA_URL + "/auth/users/new?username=%s&password=%s%s" % [_username, password, _email],
		[], 
		HTTPClient.METHOD_POST
	)
	
@warning_ignore("unused_parameter")
func _signup_complete(result: int, response_code: int, headers: PackedStringArray, body: PackedByteArray, _username: String, _password: String) -> void:
	http.request_completed.disconnect(_signup_complete)
	print(http.request_completed.get_connections())
	if response_code >= 300:
		failed.emit(response_code)
		return
	login(_username, _password)

func login(_username: String, _password: String) -> void:
	http.request_completed.connect(_set_token)
	http.request(
		Statics.HEREDITA_URL + "/auth/token",
		[], 
		HTTPClient.METHOD_POST,
		"grant_type=password&username=%s&password=%s" % [_username, _password]
	)

@warning_ignore("unused_parameter")
func _set_token(result: int, response_code: int, headers: PackedStringArray, body: PackedByteArray) -> void:
	http.request_completed.disconnect(_set_token)
	var json := JSON.new()
	json.parse(body.get_string_from_utf8())
	var response: Dictionary = json.get_data()
	token = response.access_token
	ready_to_initialize.emit()

func initialize() -> void:
	http.request_completed.connect(_set_details)
	http.request(Statics.HEREDITA_URL + "/users/me", ["Authorization: Bearer " + token.strip_edges()])

@warning_ignore("unused_parameter")
func _set_details(result: int, response_code: int, headers: PackedStringArray, body: PackedByteArray) -> void:
	http.request_completed.disconnect(_set_details)
	if result == HTTPRequest.RESULT_CANT_CONNECT:
		push_warning("Cannot connect to server (is your testing server set up?)")
		return
	
	if response_code == HTTPClient.RESPONSE_UNAUTHORIZED:
		return
	
	var json := JSON.new()
	json.parse(body.get_string_from_utf8())
	var response: Dictionary = json.get_data()
	
	id = response.id
	username = response.username
	email = response.email if response.email != null else ""
	
	for friend: Dictionary in response.friends:
		@warning_ignore("unsafe_call_argument")
		friends.append(UserPartial.new(friend.id, friend.username))
		
	for friend: Dictionary in response.sent_friend_requests:
		@warning_ignore("unsafe_call_argument")
		friend_requests_sent.append(UserPartial.new(friend.id, friend.username))
		
	for friend: Dictionary in response.received_friend_requests:
		@warning_ignore("unsafe_call_argument")
		friend_requests_received.append(UserPartial.new(friend.id, friend.username))
	
	initialized = true
	user_initialized.emit()
