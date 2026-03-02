extends VBoxContainer

@onready var text_box: LineEdit = find_child("ChatTextBox")
@onready var send_button: Button = find_child("ChatSendButton")
@onready var scroll: ScrollContainer = find_child("ChatScroll")
@onready var messages: RichTextLabel = find_child("ChatMessages")
var players_listed := []
var text_box_default_placeholder: String

var muted_text := "" #used to restore text if unmuted

func _ready() -> void:
	text_box_default_placeholder = text_box.placeholder_text
	if State.room:
		$PanelContainer/MarginContainer/ChatSP.hide()
		text_box.editable = true
		text_box.text_submitted.connect(send_typed_message.unbind(1))
		send_button.disabled = false
		send_button.pressed.connect(send_typed_message)
		State.client.message_received.connect(receive_message)
		
func _process(_delta: float) -> void:
	messages.custom_minimum_size.x = scroll.size.x - scroll.get_v_scroll_bar().size.x
		
func send_typed_message() -> void:
	if text_box.text:
		send_message(text_box.text)
		text_box.text = ""
		
func send_message(message: String) -> void:
	State.client.send("chat_message", message)
	if Settings.getv("unfocus_on_chat_submission", true):
		text_box.release_focus()

func receive_message(event: String, user_id: int, message: Variant) -> void:
	if event == "chat_message" and message is String:
		add_message(user_id, message as String)
	elif event == "is2_player_status_update":
		if State.player.status.get("muted", false):
			text_box.editable = false
			text_box.placeholder_text = "You are muted!"
			muted_text = text_box.text
			text_box.text = ""
		else:
			text_box.editable = true
			text_box.placeholder_text = text_box_default_placeholder
			text_box.text = muted_text
			muted_text = ""

func add_message(sender_id: int, message: String) -> void:
	var newline := "\n" if messages.text else ""
	var player: Player = State.room.players.getv(sender_id)
	@warning_ignore("unsafe_call_argument")
	messages.text += newline + "[b]%s[/b]: %s" % [Markdown.bb_escape(player.username),
												  Markdown.bb_escape(message)]

func _unhandled_key_input(event: InputEvent) -> void:
	if text_box.has_focus():
		return
	if event.is_action_pressed("chat_focus"):
		text_box.grab_focus.call_deferred()
