extends Node3D
class_name PlayerBalls

static var _instance: PlayerBalls

var players_listed := []


func get_player(player_id: int) -> PlayerMovement:
	if player_id == State.client.player_id:
		return get_parent().get_node("LocalPlayer")
	return get_node(str(player_id))


func _ready() -> void:
	_instance = self
	if State.room:
		State.room.players.value_changed.connect(refresh_players)
		State.client.message_received.connect(receive_update)
	refresh_players(State.room.players)


func receive_update(event: String, user_id: int, message: Variant) -> void:
	if State.room:
		if event == "avatar_update" and user_id != State.client.player_id and message is Dictionary:
			get_node(str(user_id)).frame_data = message
		if event == "chat_message":
			if user_id == State.client.player_id:
				get_parent().get_node("LocalPlayer").add_bubble(message)
			else:
				get_node(str(user_id)).add_bubble(message)


func add_player(player_id: int) -> void:
	var player_node: PlayerMovement = (
		preload("res://scenes/mapper/player/player.tscn").instantiate()
	)
	player_node.local = false
	player_node.name = str(player_id)
	player_node.get_node("Name").text = State.room.players.getv(player_id).username
	add_child(player_node)


func remove_player(player_id: int) -> void:
	var player_node := get_node(str(player_id))
	player_node.queue_free()


func refresh_players(players: ReactiveDictionary) -> void:
	for player: int in players.keys():
		if player not in players_listed and player != State.client.player_id:
			add_player(player)
			players_listed.append(player)
	var to_erase := []
	for player: int in players_listed:
		if not players.has(player):
			remove_player(player)
			to_erase.append(player)
	for removed_player: int in to_erase:
		players_listed.erase(removed_player)
