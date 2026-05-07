## Represents an API UserPartial.
extends Resource
class_name UserPartial

var id: int
var username: String
var rank: UserEnums.Rank


func _init(_id: int, _username: String, _rank: UserEnums.Rank) -> void:
	id = _id
	username = _username
	rank = _rank
