class_name MapOverlaysUI
extends VBoxContainer

signal update_requested(details: Dictionary)

@onready var overlays: MapOverlays = Map._instance.map_overlays
@onready var shown: CheckBox = %Shown
@onready var opacity: HSlider = %Opacity
@onready var opacity_label: Label = %OpacityLabel
@onready var overlay_name: LineEdit = %OverlayName
@onready var base_opacity: SpinBox = %BaseOpacity
@onready var filter_mode: OptionButton = %TextureFilter

var overlay_id := ""
var removal_confirmation: PromptInstance
var _closing := false


func _ready() -> void:
	%Close.pressed.connect(_close)
	shown.toggled.connect(func(_shown: bool) -> void: _display_changed())
	opacity.value_changed.connect(func(_value: float) -> void: _display_changed())
	%Reset.pressed.connect(_reset_display)
	%Apply.pressed.connect(_apply)
	%Remove.pressed.connect(_remove)
	overlays.changed.connect(_overlay_changed)
	var overlay := overlays.overlay_for(overlay_id)
	%Title.text = overlay["name"]
	overlay_name.text = overlay["name"]
	base_opacity.value = float(overlay["opacity"]) * 100.0
	filter_mode.select(MapOverlayData.FILTER_MODES.find(overlay.get("filter", MapOverlayData.DEFAULT_FILTER)))
	var local := overlays.local_data.overlays.has(overlay_id)
	%Editor.visible = local or State.player.privileged()
	for control: Control in [%GlobalHint, %BaseOpacityLabel, base_opacity, %Reset, %GlobalHintSeparator, %PersonalHint]:
		control.visible = not local
	_refresh_display()


func _refresh_display() -> void:
	shown.set_pressed_no_signal(overlays.visible_for(overlay_id))
	opacity.set_value_no_signal(overlays.opacity_for(overlay_id) * 100.0)
	opacity_label.text = "%d%%" % roundi(opacity.value)


func _display_changed() -> void:
	overlays.set_display(overlay_id, opacity.value / 100.0, shown.button_pressed)
	opacity_label.text = "%d%%" % roundi(opacity.value)


func _reset_display() -> void:
	overlays.reset_display(overlay_id)
	_refresh_display()


func _overlay_changed() -> void:
	if overlays.overlay_for(overlay_id).is_empty():
		_close()
	else:
		_refresh_display()


func _apply() -> void:
	var details := {
		"type": "overlay", "op": "edit", "id": overlay_id,
		"name": overlay_name.text, "filter": MapOverlayData.FILTER_MODES[filter_mode.selected]
	}
	if not overlays.local_data.overlays.has(overlay_id):
		base_opacity.apply()
		details["opacity"] = base_opacity.value / 100.0
	update_requested.emit(details)
	_close()


func _remove() -> void:
	if removal_confirmation != null:
		return
	var result := Prompts.new_fullscreen_prompt()
	if result.is_err():
		return
	removal_confirmation = result.val()
	removal_confirmation.prompt_closed.connect(func() -> void: removal_confirmation = null)
	var content := preload("res://scenes/mapper/ui/overlays/remove_overlay.tscn").instantiate()
	var local := overlays.local_data.overlays.has(overlay_id)
	var label: Label = content.get_node("Label")
	label.text = tr("mapper/overlay.remove.confirm" if local else "mapper/overlay.remove.confirm_global") % overlays.overlay_for(overlay_id)["name"]
	content.get_node("Buttons/Cancel").pressed.connect(removal_confirmation.close)
	content.get_node("Buttons/Remove").pressed.connect(_confirm_remove)
	removal_confirmation.add_child(content)


func _confirm_remove() -> void:
	if removal_confirmation == null:
		return
	removal_confirmation.close()
	update_requested.emit({"type": "overlay", "op": "delete", "id": overlay_id})
	if is_inside_tree():
		_close()


func _close() -> void:
	if _closing:
		return
	_closing = true
	if removal_confirmation != null:
		removal_confirmation.close()
	var prompt := Prompts.get_prompt_in(self)
	if prompt != null and not prompt.is_queued_for_deletion():
		prompt.close()
