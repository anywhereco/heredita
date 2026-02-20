extends HFlowContainer

var players_listed := []

func _ready() -> void:
	if State.room:
		State.room.players.value_changed.connect(refresh_players)
	refresh_players(State.room.players)

func add_player(player_id: int) -> void:
	var player_node := preload("res://scenes/mapper/ui/player.tscn").instantiate()
	player_node.name = str(player_id)
	player_node.text = State.room.players.getv(player_id)['username']
	player_node.gui_input.connect(player_clicked.bind(player_id))
	add_child(player_node)
	
func player_clicked(event: InputEvent, player_id: int) -> void:
	if event is InputEventMouseButton:
		if event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
			if State.player.operator:
				InfoPrompt.custom_prompt("Ban this player?",
				{"Cancel": Prompts.close_top_prompt(),
				 "Ban": State.client.send("ban", player_id)})
	
func remove_player(player_id: int) -> void:
	var player_node := find_child(str(player_id), false, false)
	player_node.queue_free()
		
func refresh_players(players: ReactiveDictionary) -> void:
	if get_child(0).visible:
		get_child(0).hide()
	for player: int in players.keys():
		if player not in players_listed:
			add_player(player)
			players_listed.append(player)
	var to_erase := []
	for player: int in players_listed:
		if not players.has(player):
			remove_player(player)
			to_erase.append(player)
	for removed_player: int in to_erase:
		players_listed.erase(removed_player)
	get_parent().title = "%d in room" % len(players_listed)
