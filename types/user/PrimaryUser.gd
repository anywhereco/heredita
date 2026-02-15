extends Resource
class_name PrimaryUser

signal ready_to_initialize()
signal user_initialized()

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

static func of_username_and_password(_username: String, _password: String, _http: HTTPRequest) -> void:
	var user := PrimaryUser.new()
	_http.request_completed.connect(user._set_token)
	_http.request(
		Statics.HEREDITA_URL + "/auth/token?grant_type=password&username=%s&password=%s" % [_username, _password],
		[], 
		HTTPClient.METHOD_POST
	)

func _init(_http: HTTPRequest = null, _token: String = "<no token>") -> void:
	token = _token
	http = _http

@warning_ignore("unused_parameter")
func _set_token(result: int, response_code: int, headers: PackedStringArray, body: PackedByteArray) -> void:
	var json := JSON.new()
	json.parse(body.get_string_from_utf8())
	var response: Dictionary[String, String] = json.get_data()
	token = response.access_token
	ready_to_initialize.emit()

func initialize() -> void:
	http.request_completed.connect(_set_details)
	http.request(Statics.HEREDITA_URL + "/users/me", ["Authorization: Bearer " + token.strip_edges()])

@warning_ignore("unused_parameter")
func _set_details(result: int, response_code: int, headers: PackedStringArray, body: PackedByteArray) -> void:
	if result == HTTPRequest.RESULT_CANT_CONNECT:
		push_warning("Cannot connect to server (is your testing server set up?)")
		return
	
	if response_code == HTTPClient.RESPONSE_UNAUTHORIZED:
		State.user = null # When we have time, reconsider if this is what we want to do
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
