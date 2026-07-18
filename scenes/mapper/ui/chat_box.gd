extends VBoxContainer

@onready var text_box: LineEdit = find_child("ChatTextBox")
@onready var send_button: Button = find_child("ChatSendButton")
@onready var scroll: ScrollContainer = find_child("ChatScroll")
@onready var messages: RichTextLabel = find_child("ChatMessages")
var players_listed := []
var text_box_default_placeholder: String
var messages_text_full := ""

var muted := false
var muted_text := ""  #used to restore text if unmuted

const TYPING_TIMER = 4 #seconds typing indicator should last
var typing_timer: float = 0

const MAX_LINES = 500

func _ready() -> void:
	text_box_default_placeholder = text_box.placeholder_text
	if State.room:
		$PanelContainer/MarginContainer/ChatSP.hide()
		text_box.editable = true
		text_box.text_changed.connect(is_typing)
		text_box.text_submitted.connect(send_typed_message.unbind(1))
		send_button.disabled = false
		send_button.pressed.connect(send_typed_message)
		State.client.message_received.connect(receive_message)


func _process(delta: float) -> void:
	messages.custom_minimum_size.x = scroll.size.x - scroll.get_v_scroll_bar().size.x
	if typing_timer > 0:
		typing_timer = max(0, typing_timer-delta)
		if typing_timer == 0:
			State.client.send("typing_status", 0)

func is_typing(text: String) -> void:
	if text:
		if typing_timer == 0:
			State.client.send("typing_status", 1)
		typing_timer = TYPING_TIMER
	else:
		typing_timer = 0
		State.client.send("typing_status", 0)

func send_typed_message() -> void:
	if text_box.text:
		send_message(text_box.text)
		text_box.text = ""


func send_message(message: String) -> void:
	State.client.send("chat_message", message)
	typing_timer = 0
	State.client.send("typing_status", 0)
	if Settings.getv("unfocus_on_chat_submission", true):
		text_box.release_focus()
	#TODO put things in chat for system events too (like banning/kicking)


func receive_message(event: String, user_id: int, message: Variant) -> void:
	if event == "chat_message" and message is String:
		add_chat_message(user_id, message as String)
	elif event == "is2_player_join":
		var player: Player = State.room.players.getv(message["player_id"])
		add_message("%s joined the room" % player.username)
	elif event == "is2_player_status_update":
		if State.player.status.get("muted", false) and not muted_text:
			text_box.editable = false
			text_box.placeholder_text = "You are muted!"
			muted_text = text_box.text
			muted = true
			text_box.text = ""
		elif muted:
			text_box.editable = true
			text_box.placeholder_text = text_box_default_placeholder
			text_box.text = muted_text
			muted_text = ""
			muted = false


func add_chat_message(sender_id: int, message: String) -> void:
	var player: Player = State.room.players.getv(sender_id)
	add_message(
		"[b]%s[/b]: %s" % [Markdown.bb_escape(player.username), TextFilter.filter_text(Markdown.bb_escape(message))]
	)


func add_message(message: String) -> void:
	var newline := "\n" if messages_text_full else ""
	@warning_ignore("unsafe_call_argument")
	messages_text_full += newline + message
	messages.text += newline + message
	if messages.text.get_slice_count("\n") > MAX_LINES:
		messages.text = messages.text.substr(messages.text.find("\n")+1)
	

func _unhandled_key_input(event: InputEvent) -> void:
	if text_box.has_focus():
		return
	if event.is_action_pressed("chat_focus"):
		text_box.grab_focus.call_deferred()
