class_name MapTextTool
extends Resource

const HANDLE_RADIUS := 10.0
const MOVE_HANDLE := 4
const MOVE_HANDLE_RADIUS := 12.0

var ui: MapTextUI
var selected_id := ""
var draft: Dictionary = {}
var is_dragging := false
var _creating := false
var _handle := -1
var _drag_origin := Vector2.ZERO
var _drag_screen := Vector2.ZERO
var _original_points: Array = []
var _drag_changed := false


func _map_ready() -> void:
	ui = UIRoot._instance.text_ui
	ui.settings_changed.connect(_settings_changed)
	ui.straighten_requested.connect(_straighten_requested)
	ui.tab_changed.connect(func(_tab: int) -> void: cancel_drag())
	Map._instance.map_text.changed.connect(_text_changed)
	var controls := MapTextControls.new()
	controls.tool = self
	UIRoot._instance.add_child(controls)
	UIRoot._instance.move_child(controls, 0)
	MapTextMesh.warm_up()


func get_selected() -> Dictionary:
	if is_dragging:
		return draft
	return Map._instance.map_text.data.labels.get(selected_id, {})


func text_events(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		if is_dragging:
			cancel_drag()
		else:
			_select("")
		Map._instance.get_viewport().set_input_as_handled()
		return
	if is_dragging:
		if event is InputEventMouseMotion:
			@warning_ignore("unsafe_call_argument")
			_drag_to(event.position)
			Map._instance.get_viewport().set_input_as_handled()
		elif (
			event is InputEventMouseButton
			and event.button_index == MOUSE_BUTTON_LEFT
			and not event.pressed
		):
			finish_drag()
			Map._instance.get_viewport().set_input_as_handled()
		return
	if (
		not event is InputEventMouseButton
		or not event.pressed
		or event.button_index != MOUSE_BUTTON_LEFT
	):
		return
	var map := Map._instance
	if not map.loaded:
		return
	@warning_ignore("unsafe_call_argument")
	var pixel := _pixel_at(event.position)
	if not pixel.is_finite():
		return
	if ui.current_tab == 2:
		var selected := get_selected()
		if not selected.is_empty():
			@warning_ignore("unsafe_call_argument")
			var handle := _handle_at(event.position, selected)
			if handle != -1:
				map.get_viewport().gui_release_focus()
				@warning_ignore("unsafe_call_argument")
				_start_drag(selected, handle, pixel, event.position)
				return
	if not map.is_in_bounding_box(pixel, Vector2.ZERO, map.original_map_size):
		return
	map.get_viewport().gui_release_focus()
	if ui.current_tab == 1:
		@warning_ignore("unsafe_call_argument")
		var id := map.map_text.get_at_position(pixel, _pixel_margin(event.position))
		if not id.is_empty():
			_send_update({"type": "text", "op": "delete", "id": id})
			if selected_id == id:
				_select("")
		return
	if ui.current_tab == 2:
		@warning_ignore("unsafe_call_argument")
		var id := map.map_text.get_at_position(pixel, _pixel_margin(event.position))
		_select(id)
		if not id.is_empty():
			@warning_ignore("unsafe_call_argument")
			_start_drag(get_selected(), -1, pixel, event.position)
		return
	if ui.content.text.strip_edges().is_empty():
		return
	var owner_id := State.client.player_id if State.client else -1
	var new_label_id := "%d:%d:%d" % [owner_id, Time.get_ticks_usec(), randi()]
	var label := ui.settings()
	label["id"] = new_label_id
	var width := minf(
		MapTextData.text_width(ui.content.text, ui.font_size.value), map.original_map_size.x
	)
	var start := Vector2(
		clampf(pixel.x - width / 2.0, 0.0, map.original_map_size.x - width), pixel.y
	)
	label["points"] = _straight_points(start, start + Vector2(width, 0.0))
	MapTextData.ensure_minimum_length(label, map.original_map_size)
	selected_id = new_label_id
	@warning_ignore("unsafe_call_argument")
	_start_drag(label, 3, pixel, event.position)
	_creating = true
	ui.set_selected(label)
	map.map_text.preview_label(draft)


func _start_drag(label: Dictionary, handle: int, pixel: Vector2, screen: Vector2) -> void:
	is_dragging = true
	_creating = false
	_handle = handle
	_drag_origin = pixel
	_drag_screen = screen
	_original_points = label["points"].duplicate(true)
	draft = label.duplicate(true)
	_drag_changed = false


func _drag_to(screen: Vector2) -> void:
	var pixel := _pixel_at(screen)
	if not pixel.is_finite():
		return
	if _creating and screen.distance_to(_drag_screen) < 4.0 and not _drag_changed:
		return
	var bounds := Map._instance.original_map_size
	if _handle != MOVE_HANDLE and _handle != -1:
		pixel = pixel.clamp(Vector2.ZERO, bounds)
	var points := _original_points.duplicate(true)
	var delta := pixel - _drag_origin
	if _creating:
		points = _straight_points(_drag_origin, pixel)
	elif _handle == -1 or _handle == MOVE_HANDLE:
		# Limit translation as a whole so moving a label preserves its curve at map edges.
		var minimum := Vector2.INF
		var maximum := -Vector2.INF
		for point: Array in points:
			minimum = minimum.min(ISUtil.to_vec2(point))
			maximum = maximum.max(ISUtil.to_vec2(point))
		delta = delta.clamp(-minimum, bounds - maximum)
		for idx in 4:
			points[idx] = ISUtil.from_vec2(ISUtil.to_vec2(points[idx] as Array) + delta)
	else:
		points[_handle] = ISUtil.from_vec2(
			(ISUtil.to_vec2(points[_handle] as Array) + delta).clamp(Vector2.ZERO, bounds)
		)
		# An endpoint carries its adjacent tangent handle along with it.
		if _handle == 0 or _handle == 3:
			var tangent := 1 if _handle == 0 else 2
			points[tangent] = ISUtil.from_vec2(
				(ISUtil.to_vec2(points[tangent] as Array) + delta).clamp(Vector2.ZERO, bounds)
			)
	draft["points"] = points
	# Translation preserves the span, so only shape changes need normalization.
	if _creating or (_handle != -1 and _handle != MOVE_HANDLE):
		MapTextData.ensure_minimum_length(draft, bounds)
	_drag_changed = true
	Map._instance.map_text.preview_label(draft)


func finish_drag() -> void:
	if not is_dragging:
		return
	if MapTextData.curve_for(draft).get_baked_length() < 0.01:
		cancel_drag()
		return
	var update := {"type": "text", "id": selected_id, "op": "create" if _creating else "edit"}
	if _creating:
		update.merge(draft)
	else:
		update["points"] = draft["points"]
	var send := _creating or _drag_changed
	is_dragging = false
	draft = {}
	ui.current_tab = 2 # Edit, since we're done making the text
	if send:
		_send_update(update)
	_select(selected_id)


func cancel_drag() -> void:
	if not is_dragging:
		return
	is_dragging = false
	draft = {}
	var texts := Map._instance.map_text
	if texts.data.labels.has(selected_id):
		texts.preview_label(texts.data.labels[selected_id])
	else:
		texts.remove_label(selected_id)
		_select("")


func _select(id: String) -> void:
	selected_id = id
	ui.set_selected(get_selected())


func _settings_changed() -> void:
	if ui.current_tab != 2 or selected_id.is_empty() or ui.content.text.strip_edges().is_empty():
		return
	var update := ui.settings()
	update.merge({"type": "text", "op": "edit", "id": selected_id})
	_send_update(update)


func _straighten_requested() -> void:
	var label := get_selected()
	if label.is_empty():
		return
	var points: Array = label["points"]
	_send_update(
		{
			"type": "text",
			"op": "edit",
			"id": selected_id,
			"points":
			_straight_points(ISUtil.to_vec2(points[0] as Array), ISUtil.to_vec2(points[3] as Array))
		}
	)


func _text_changed(id: String) -> void:
	if id.is_empty():
		cancel_drag()
		_select("")
	elif id == selected_id and not is_dragging:
		var label := get_selected()
		if label.is_empty():
			_select("")
		elif not ui.content.has_focus():
			ui.set_selected(label)


func _send_update(details: Dictionary) -> void:
	var texts := Map._instance.map_text
	if not texts.apply_update(details):
		if texts.data.labels.has(selected_id):
			texts.preview_label(texts.data.labels[selected_id])
		else:
			texts.remove_label(selected_id)
			_select("")
		return
	if State.client:
		State.client.send("map_update", details)


func move_handle_position(label: Dictionary) -> Vector2:
	var map := Map._instance
	var camera := map.get_viewport().get_camera_3d()
	@warning_ignore("unsafe_call_argument")
	var node: MapTextLabel = map.map_text.labels.get(String(label["id"]))
	if camera == null or node == null or node.curve == null:
		return Vector2.INF
	var curve := node.curve
	var length := curve.get_baked_length()
	var middle := length / 2.0
	var pixel := curve.sample_baked(middle)
	var tangent := (
		curve.sample_baked(minf(length, middle + 1.0)) - curve.sample_baked(maxf(0.0, middle - 1.0))
	)
	var normal := Vector2(-tangent.y, tangent.x).normalized()
	if normal.is_zero_approx():
		normal = Vector2.UP
	var center := map.map_space_to_world_space(pixel)
	var edge := map.map_space_to_world_space(pixel + normal * node.half_height)
	var center_position := Vector3(center.x, 0.035, center.y)
	var edge_position := Vector3(edge.x, 0.035, edge.y)
	if camera.is_position_behind(center_position) or camera.is_position_behind(edge_position):
		return Vector2.INF
	var screen_center := camera.unproject_position(center_position)
	var screen_edge := camera.unproject_position(edge_position)
	var direction := (screen_edge - screen_center).normalized()
	if direction.is_zero_approx():
		direction = Vector2.UP
	# Keep the handle outside the glyphs and a consistent size at every zoom level.
	return screen_edge + direction * (MOVE_HANDLE_RADIUS + 8.0)


func _handle_at(screen: Vector2, label: Dictionary) -> int:
	var camera := Map._instance.get_viewport().get_camera_3d()
	var closest := -1
	var distance := HANDLE_RADIUS
	var points: Array = label["points"]
	for idx in 4:
		var world := Map._instance.map_space_to_world_space(ISUtil.to_vec2(points[idx] as Array))
		var position := Vector3(world.x, 0.035, world.y)
		if camera.is_position_behind(position):
			continue
		var hit := screen.distance_to(camera.unproject_position(position))
		if hit < distance:
			distance = hit
			closest = idx
	if closest == -1 and screen.distance_to(move_handle_position(label)) <= MOVE_HANDLE_RADIUS:
		return MOVE_HANDLE
	return closest


func _pixel_margin(screen: Vector2) -> float:
	var first := _pixel_at(screen)
	var second := _pixel_at(screen + Vector2(6.0, 0.0))
	return maxf(0.5, first.distance_to(second)) if second.is_finite() else 0.5


func _pixel_at(screen: Vector2) -> Vector2:
	var camera := Map._instance.get_viewport().get_camera_3d()
	if camera == null:
		return Vector2.INF
	var hit: Variant = Plane.PLANE_XZ.intersects_ray(
		camera.project_ray_origin(screen), camera.project_ray_normal(screen)
	)
	if not hit is Vector3:
		return Vector2.INF
	var position: Vector3 = hit
	return Map._instance.world_space_to_map_space(Vector2(position.x, position.z))


static func _straight_points(start: Vector2, end: Vector2) -> Array:
	return [
		ISUtil.from_vec2(start),
		ISUtil.from_vec2(start.lerp(end, 1.0 / 3.0)),
		ISUtil.from_vec2(start.lerp(end, 2.0 / 3.0)),
		ISUtil.from_vec2(end)
	]
