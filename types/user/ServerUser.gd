class_name Player

var peer_id: int
var username: String
var logged_in: bool
var profile := {}
var flags: int
var status: Dictionary
var operator: bool

func _init(peer: int, dict: Dictionary) -> void:
	peer_id = peer
	username = dict["username"]
	logged_in = dict["logged_in"]
	operator = dict.get("operator", false)
	#serverside
	flags = dict.get("flags", 0)
	status = dict.get("status", {})
	#clientside
	profile = dict.get("profile", {})

func get_info() -> Dictionary:
	return {"username": username,
			"logged_in": logged_in,
			"profile": profile,
			"operator": operator}
			
static func from_info(dict: Dictionary) -> Player:
	return Player.new(-2, dict)
