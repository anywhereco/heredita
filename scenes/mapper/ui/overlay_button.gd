extends MenuButton

const MODIFICATION = preload("res://scenes/mapper/ui/overlays/overlays.tscn")
const OPENFOLDER = preload("uid://btb4jabo6nmoe")
const OPACITY_PRESETS := [10, 25, 40, 60, 100]

enum Action { SHOW, RESET = 100, MODIFY }

@onready var overlays: MapOverlays = Map._instance.map_overlays

var modification: MapOverlaysUI
var _uploading := false
var _overlay_menus: Dictionary[String, PopupMenu] = {}


func _ready() -> void:
	get_popup().about_to_popup.connect(_build_menu)
	get_popup().id_pressed.connect(_item_pressed)
	overlays.changed.connect(_refresh_menus)
	State.client.message_received.connect(_message_received)


func _build_menu() -> void:
	var popup := get_popup()
	popup.clear()
	for menu: PopupMenu in _overlay_menus.values():
		menu.free()
	_overlay_menus.clear()
	popup.add_icon_item(OPENFOLDER, tr("mapper/overlay.load_local"), 0)
	if State.player.privileged():
		popup.add_icon_item(OPENFOLDER, tr("mapper/overlay.load_global"), 1)
	popup.add_separator()
	for data: MapOverlayData in [overlays.global_data, overlays.local_data]:
		for overlay: Dictionary in data.overlays.values():
			var id: String = overlay["id"]
			var menu := PopupMenu.new()
			menu.name = "Overlay%d" % _overlay_menus.size()
			menu.hide_on_checkable_item_selection = false
			popup.add_child(menu)
			_overlay_menus[id] = menu
			var scope := tr("mapper/overlay.global") if data == overlays.global_data else tr("mapper/overlay.local")
			popup.add_submenu_node_item("%s (%s)" % [overlay["name"], scope], menu)
			popup.set_item_metadata(popup.item_count - 1, id)
			popup.set_item_as_checkable(popup.item_count - 1, true)
			popup.set_item_checked(popup.item_count - 1, overlays.visible_for(id))
			menu.add_check_item(tr("mapper/overlay.shown"), Action.SHOW)
			menu.add_separator(tr("mapper/overlay.opacity"))
			for idx in OPACITY_PRESETS.size():
				menu.add_radio_check_item("%d%%" % OPACITY_PRESETS[idx], idx + 1)
			menu.add_separator()
			if data == overlays.global_data:
				menu.add_item(tr("mapper/overlay.reset"), Action.RESET)
			menu.add_item(tr("mapper/overlay.modify"), Action.MODIFY)
			menu.about_to_popup.connect(_refresh_overlay_menu.bind(id))
			menu.id_pressed.connect(_overlay_action.bind(id))
			_refresh_overlay_menu(id)
	if _overlay_menus.is_empty():
		popup.add_item(tr("mapper/overlay.empty"))
		popup.set_item_disabled(popup.item_count - 1, true)


func _item_pressed(id: int) -> void:
	if id in [0, 1]:
		load_image(id == 1)


func _refresh_overlay_menu(id: String) -> void:
	var menu := _overlay_menus[id]
	menu.set_item_checked(0, overlays.visible_for(id))
	for idx in get_popup().item_count:
		if get_popup().get_item_metadata(idx) == id:
			get_popup().set_item_checked(idx, overlays.visible_for(id))
	for idx in OPACITY_PRESETS.size():
		menu.set_item_checked(idx + 2, is_equal_approx(overlays.opacity_for(id) * 100.0, OPACITY_PRESETS[idx]))


func _refresh_menus() -> void:
	for id: String in _overlay_menus:
		if not overlays.overlay_for(id).is_empty():
			_refresh_overlay_menu(id)


func _overlay_action(action: int, id: String) -> void:
	if overlays.overlay_for(id).is_empty():
		return
	if action == Action.SHOW:
		overlays.set_display(id, overlays.opacity_for(id), not overlays.visible_for(id))
	elif action >= 1 and action <= OPACITY_PRESETS.size():
		overlays.set_display(id, OPACITY_PRESETS[action - 1] / 100.0, overlays.visible_for(id))
	elif action == Action.RESET:
		overlays.reset_display(id)
	elif action == Action.MODIFY:
		_modify_overlay(id)
	_refresh_overlay_menu(id)


func _modify_overlay(id: String) -> void:
	get_popup().hide()
	var result := Prompts.new_fullscreen_prompt()
	if result.is_err():
		return
	modification = MODIFICATION.instantiate()
	modification.overlay_id = id
	modification.update_requested.connect(_submit.bind(overlays.local_data.overlays.has(id)))
	var prompt: PromptInstance = result.val()
	prompt.add_child(modification)


func load_image(global: bool) -> void:
	if _uploading or (global and not State.player.privileged()):
		return
	var file := await FilePrompter.load_file(
		self, ImagePickerButton.NO_SVG_NO_MAP_FILTER,
		ImagePickerButton.NO_SVG_NO_MAP_FILTER_WEB, "overlay"
	)
	var image := MapOverlayData.image_from_buffer(file["buffer"] as PackedByteArray, String(file["extension"]).to_lower())
	if image == null:
		_error("mapper/overlay.invalid_image")
		return
	var png := image.save_png_to_buffer()
	if png.size() > MapOverlayData.MAX_IMAGE_BYTES:
		_error("mapper/overlay.invalid_image")
		return
	var id := ("global_" if global else "local_") + Crypto.new().generate_random_bytes(16).hex_encode()
	var details := {
		"type": "overlay", "op": "create", "id": id,
		"name": String(file.get("filename", tr("mapper/overlay.default_name"))).get_basename().left(128),
		"image": png,
		"opacity": MapOverlayData.DEFAULT_OPACITY
	}
	await _submit(details, not global)


func _submit(details: Dictionary, local: bool) -> void:
	if local:
		if not overlays.apply_update(details, true):
			_error("mapper/overlay.rejected")
		return
	if not State.player.privileged() or _uploading:
		return
	if details["op"] == "create":
		_uploading = true
		var error := await State.client.chunk_sender.send(
			ISUtil.BinaryEvents.OVERLAY_UPDATE, -1, var_to_bytes(details)
		)
		_uploading = false
		if error != OK:
			_error("mapper/overlay.send_failed")
		return
	State.client.send("map_update", details)


func _message_received(event: String, _player_id: int, _details: Variant) -> void:
	if event == "overlay_rejected":
		_error("mapper/overlay.rejected")


func _error(key: String) -> void:
	InfoPrompt.prompt(key)
