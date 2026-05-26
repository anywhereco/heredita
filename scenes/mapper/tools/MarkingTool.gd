class_name MarkingTool
extends Resource

const DEFAULT_SCALE := 1.0

var ui: TabContainer


func _map_ready() -> void:
	ui = UIRoot._instance.marking_ui
	ui.edit_requested.connect(_edit_requested)


func marking_events(event: InputEvent) -> void:
	if not (event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT):
		return
	var world_pos := PlayerMovement._local_inst.mouse_pos_on_map()
	if not Map._instance.map_world_bounds.has_point(world_pos):
		return
	match ui.current_tab:
		0:
			create_marking(world_pos)
		1:
			delete_marking(world_pos)
		2:
			select_marking(world_pos)


func create_marking(position: Vector2) -> void:
	var id := _new_marking_id()
	var marking_type: String = ui.create_type
	
	@warning_ignore("unsafe_call_argument")
	var details := {
		"type": "marking",
		"op": "create",
		"id": id,
		"marking_type": marking_type,
		"position": ISUtil.from_vec2(position),
		"scale": DEFAULT_SCALE,
		"rotation": 0.0,
		"color": ISUtil.from_color(ui.create_color_picker.color.value),
		"name": ""
	}
	_send_update(details)


func delete_marking(position: Vector2) -> void:
	var allowed_types: Array[String] = ui.delete_types()
	if allowed_types.is_empty():
		return
	var marking := Map._instance.map_markings.get_at_position(position, allowed_types)
	if marking == null:
		return
	_send_update({"type": "marking", "op": "delete", "id": marking.id})
	if ui.selected_marking_id == marking.id:
		ui.set_selected(null)


func select_marking(position: Vector2) -> void:
	ui.set_selected(Map._instance.map_markings.get_at_position(position))


func _edit_requested(id: String, changes: Dictionary) -> void:
	var details := {"type": "marking", "op": "edit", "id": id}
	for key: String in changes:
		details[key] = changes[key]
	_send_update(details)


func _send_update(details: Dictionary) -> void:
	if State.client:
		State.client.send("map_update", details)
	else:
		Map._instance.get_map_update(details)


func _new_marking_id() -> String:
	var owner_id := State.client.player_id if State.client else -1
	return "%d:%d:%d" % [owner_id, Time.get_ticks_usec(), randi()]
