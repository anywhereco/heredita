extends HFlowContainer

# textures
const BADGE_ADMINISTRATOR = preload("uid://k0f4q3uf71dt")
const BADGE_DEVELOPER = preload("uid://x4locc6fhj3")
const BADGE_MODERATOR = preload("uid://bo4oxu4rpjud1")
const BADGE_PLAYER_LOGGEDOUT = preload("uid://cakvortcaev5s")
const BADGE_PLAYER = preload("uid://bqlqc6ldgd3kc")
const BADGE_OPERATOR = preload("uid://dwh3xvonrqo0u")

var players_listed := []


func _ready() -> void:
	if State.room:
		State.client.message_received.connect(message_received)
		State.room.players.value_changed.connect(refresh_players)
		refresh_players(State.room.players)
		State.client.send("player_update_request")

func purge_paint_player(player_id: int) -> void:
	InfoPrompt.custom_prompt(
		"Purge this player's paint?",
		{
			"Cancel": Prompts.close_top_prompt,
			"Purge paint": (func() -> void:
				Prompts.close_top_prompt()
				State.client.send("purge_player", player_id)
				)
		}
	)

func ban_player(player_id: int) -> void:
	InfoPrompt.custom_prompt(
		"Ban this player?",
		{
			"Cancel": Prompts.close_top_prompt,
			"Ban": (func() -> void:
				Prompts.close_top_prompt()
				State.client.send("ban", player_id)
				),
			"Ban and clear paint": (func() -> void:
				Prompts.close_top_prompt()
				State.client.send("purge_player", player_id)
				State.client.send("ban", player_id)
				)
		}
	)


func kick_player(player_id: int) -> void:
	InfoPrompt.custom_prompt(
		"Kick this player?",
		{
			"Cancel": Prompts.close_top_prompt,
			"Kick": (func() -> void:
				Prompts.close_top_prompt()
				State.client.send("kick", player_id)
				),
			"Kick and clear paint": (func() -> void:
				Prompts.close_top_prompt()
				State.client.send("purge_player", player_id)
				State.client.send("kick", player_id)
				)
		}
	)


func mute_player(player_id: int) -> void:
	State.client.send("mute", player_id)


func unmute_player(player_id: int) -> void:
	State.client.send("unmute", player_id)


func make_player_operator(player_id: int) -> void:
	State.client.send("make_operator", player_id)


func remove_player_operator(player_id: int) -> void:
	State.client.send("remove_operator", player_id)

func player_clicked(player_node: Control, player_id: int) -> void:
	var menu := CPopupMenu.new()
	var player: Player = State.room.players.getv(player_id)
	if State.player.privileged_over(player) and player_id != State.client.player_id:
		menu.add_item("Ban", ban_player.bind(player_id))
		menu.add_item("Kick", kick_player.bind(player_id))
		menu.add_item("Purge paint", purge_paint_player.bind(player_id))
		if player.status.get("muted", false):
			menu.add_item("Unmute", unmute_player.bind(player_id))
		else:
			menu.add_item("Mute", mute_player.bind(player_id))
		if player.operator:
			menu.add_item("Remove operator", remove_player_operator.bind(player_id))
	if State.player.privileged() and player_id != State.client.player_id:
		if not player.operator:
			menu.add_item("Make operator", make_player_operator.bind(player_id))
	if not menu.item_count():  #no items so no menu
		menu.queue_free()
		return
	menu.display()
	@warning_ignore("unsafe_call_argument")
	menu.align_bottom(player_node.get_node("Elements/Label"))
	menu.bump()


func add_player(player_id: int) -> void:
	var player: Player = State.room.players.getv(player_id)
	var player_node: PlayerListElement = (
		preload("res://scenes/mapper/ui/player_list/player.tscn").instantiate()
	)
	player_node.name = str(player_id)
	player_node.get_node("Elements/Label").text = player.username
	player_node.get_node("Button").pressed.connect(player_clicked.bind(player_node, player_id))
	add_child(player_node)
	if not player.logged_in:
		player_node.add_badge(BADGE_PLAYER_LOGGEDOUT, "Player")
		if player.operator:
			player_node.add_badge(BADGE_OPERATOR, "Room operator")
		return
	match player.rank:
		UserEnums.Rank.PLAYER:
			player_node.add_badge(BADGE_PLAYER, "Logged in")
			if player.operator:
				player_node.add_badge(BADGE_OPERATOR, "Room operator")
		UserEnums.Rank.MODERATOR:
			player_node.add_badge(BADGE_MODERATOR, "Moderator")
		UserEnums.Rank.ADMIN:
			player_node.add_badge(BADGE_ADMINISTRATOR, "Admin")
		UserEnums.Rank.DEV:
			player_node.add_badge(BADGE_DEVELOPER, "Developer")


func remove_player(player_id: int) -> void:
	var player_node := get_node(str(player_id))
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

func message_received(event: String, _player_id: int, details: Variant) -> void:
	if event == "is2_player_operator_status_update":
		var player_id: int = details.get("player_id")
		var player: Player = State.room.players.getv(player_id)
		var player_node := get_node(str(player_id))
		if details.get("operator"):
			if player.rank < UserEnums.Rank.MODERATOR:
				player_node.add_badge(BADGE_OPERATOR, "Room operator")
		else:
			player_node.elements.find_child("Room operator", false, false).queue_free()
