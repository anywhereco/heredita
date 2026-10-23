class_name MapTextControls
extends Node2D

const CURVE_COLOR := Color(0.3, 0.85, 1.0)

var tool: MapTextTool


func _process(_delta: float) -> void:
	visible = (
		UIRoot._instance.visible
		and MapperRoot._instance.tool.value == MapperRoot.Tool.TEXT
		and (tool.ui.current_tab == 2 or tool.is_dragging)
	)
	if visible:
		queue_redraw()


func _draw() -> void:
	var label := tool.get_selected()
	if label.is_empty():
		return
	var camera := get_viewport().get_camera_3d()
	if camera == null:
		return
	var points: Array = label["points"]
	var screen_points := PackedVector2Array()
	for point: Array in points:
		var world := Map._instance.map_space_to_world_space(ISUtil.to_vec2(point))
		var position := Vector3(world.x, 0.035, world.y)
		if camera.is_position_behind(position):
			return
		screen_points.append(camera.unproject_position(position))
	draw_line(screen_points[0], screen_points[1], Color(0.05, 0.06, 0.08, 0.6), 1.0, true)
	draw_line(screen_points[2], screen_points[3], Color(0.05, 0.06, 0.08, 0.6), 1.0, true)
	var path := PackedVector2Array()
	for idx in 65:
		var pixel := ISUtil.to_vec2(points[0] as Array).bezier_interpolate(
			ISUtil.to_vec2(points[1] as Array),
			ISUtil.to_vec2(points[2] as Array),
			ISUtil.to_vec2(points[3] as Array),
			float(idx) / 64.0
		)
		var world := Map._instance.map_space_to_world_space(pixel)
		var position := Vector3(world.x, 0.035, world.y)
		if camera.is_position_behind(position):
			return
		path.append(camera.unproject_position(position))
	draw_polyline(path, CURVE_COLOR, 1.5, true)
	if tool.ui.current_tab == 2:
		var move_position := tool.move_handle_position(label)
		if move_position.is_finite():
			_draw_move_handle(move_position)
	for idx in 4:
		var color := Color.WHITE if idx == 0 or idx == 3 else CURVE_COLOR
		draw_circle(screen_points[idx], 7.0, Color(0.05, 0.06, 0.08, 0.9), true, -1.0, true)
		draw_circle(screen_points[idx], 5.0, color, true, -1.0, true)


func _draw_move_handle(center: Vector2) -> void:
	var radius := MapTextTool.MOVE_HANDLE_RADIUS
	draw_circle(center, radius, Color(0.05, 0.06, 0.08, 0.9), true, -1.0, true)
	draw_arc(center, radius, 0.0, TAU, 32, CURVE_COLOR, 1.5, true)
	for direction: Vector2 in [Vector2.LEFT, Vector2.RIGHT, Vector2.UP, Vector2.DOWN]:
		var tip := center + direction * 8.0
		var side := Vector2(-direction.y, direction.x) * 3.0
		draw_line(center, tip, Color.WHITE, 1.5, true)
		draw_polyline(
			PackedVector2Array([tip - direction * 3.0 + side, tip, tip - direction * 3.0 - side]),
			Color.WHITE,
			1.5,
			true
		)
