class_name Room

var name := "Unnamed Room"
var description := ""
var player_limit := 8
var password := ""

var map: MapData

## ReactiveDictionary[int, Player]
var players: ReactiveDictionary = ReactiveDictionary.new({})
var player_ids_chronological: Array[int] = []
var id_iterator := 0  #next id for use
var close_on_empty := true

var banned_ips := []


func taken_usernames() -> Array[String]:
	var l: Array[String] = []
	for player_id: int in players.keys():
		if players.getv(player_id).logged_in:
			l.append(players.getv(player_id).username)
	return l


func player_info() -> Dictionary:
	var l := {}
	for player_id: int in players.keys():
		l[player_id] = {
			"username": players.getv(player_id).username,
			"logged_in": players.getv(player_id).logged_in,
			"profile": players.getv(player_id).profile,
			"operator": players.getv(player_id).operator,
			"rank": players.getv(player_id).rank
		}
	return l


func to_json() -> Dictionary:
	return {
		"name": name,
		"description": description,
		"player_count": players.size(),
		"player_limit": player_limit,
		"password_protected": not password.is_empty()
	}
