class_name BrushTool
extends Resource

var size: int = 1
var shape: BrushShapeMap = BrushShapeMap.new()
var is_painting: bool = false
var paint_color: ReactiveColor = ReactiveColor.new(Color.WHITE)
var target_color: ReactiveColor = ReactiveColor.new(Color.WHITE)
var is_targeted: ReactiveBool = ReactiveBool.new(true)
var _last_sent_pos := Vector2(-INF, -INF)
var _last_painted_pos := Vector2(-INF, -INF)


func _init() -> void:
	pass


func _map_ready() -> void:
	UIRoot._instance.brush_ui.size_controller.brush_size.value_changed.connect(
		_brush_size_changed.unbind(1)
	)
	_brush_size_changed()
	target_color = UIRoot._instance.brush_ui.target_picker.color
	target_color.value_changed.connect(func(_color: ReactiveColor) -> void: _update_brush())
	paint_color = UIRoot._instance.brush_ui.paint_picker.color
	paint_color.value_changed.connect(func(_color: ReactiveColor) -> void: _update_brush())
	paint_color.value = Color()  #black feels more sensible as a default for paint
	target_color.value = Map._instance.default_target_color
	UIRoot._instance.brush_ui.untargeted_checkbox.toggled.connect(
		func(toggled: bool) -> void: is_targeted.value = not toggled
	)
	is_targeted.value_changed.connect(
		func(targeted: ReactiveBool) -> void:
			_update_brush()
			UIRoot._instance.brush_ui.untargeted_checkbox.button_pressed = not targeted.value
			if not targeted.value:
				UIRoot._instance.brush_ui.target_picker.modulate = Color(1, 1, 1, .5)
			else:
				UIRoot._instance.brush_ui.target_picker.modulate = Color(1, 1, 1, 1)
	)


func brush_events(event: InputEvent) -> void:
	if event.is_action_pressed("pick_paint"):
		var color := Map._instance.get_pixel_at(Map._instance.map_pos.value)
		if color.a == 1:
			UIRoot._instance.brush_ui.paint_picker.color.value = color
	if event.is_action_pressed("pick_target"):
		var color := Map._instance.get_pixel_at(Map._instance.map_pos.value)
		if color.a == 1:
			UIRoot._instance.brush_ui.target_picker.color.value = color
			is_targeted.value = true
	if event.is_action_pressed("switch_targeting_status"):
		is_targeted.value = not is_targeted.value

	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		is_painting = true
		_last_sent_pos = Vector2(-INF, -INF)
		_last_painted_pos = Vector2(-INF, -INF)
	if (
		event is InputEventMouseButton
		and not event.pressed
		and event.button_index == MOUSE_BUTTON_LEFT
	):
		is_painting = false


func brush_action(
	brush_size: int, paint: Color, target: Color, offset: Vector2 = Vector2.ZERO
) -> void:
	if offset:
		Map._instance.set_pixels_at_maybe_targeted(
			shape.get_vec2s(brush_size), paint, target, is_targeted.value, offset
		)
	else:
		Map._instance.set_pixels_at_map_pos_targeted(
			shape.get_vec2s(brush_size), paint, target, is_targeted.value
		)


func _brush_size_changed() -> void:
	size = UIRoot._instance.brush_ui.size_controller.brush_size.value
	_update_brush()


func _update_brush() -> void:
	var mod: Color = paint_color.value * (Settings.getv("map_brightness") as float)
	mod.a = 0.5
	Map._instance.update_brush_preview_material(
		size, shape.get_as_image(size), target_color.value, is_targeted.value, mod
	)
	_last_painted_pos = Vector2(-INF, -INF)


func _send_brush_update(pos: Vector2) -> void:
	State.client.send_binary(
		ISUtil.BinaryEvents.BRUSH_UPDATE,
		0,
		ISUtil.encode_brush_update(
			pos, size, paint_color.value, target_color.value, is_targeted.value
		)
	)


func _process(_delta: float) -> void:
	if is_painting:
		var cur_pos := Map._instance.map_pos.value
		if cur_pos != _last_painted_pos:
			_last_painted_pos = cur_pos
			brush_action(size, paint_color.value, target_color.value)
		if State.client:
			if cur_pos != _last_sent_pos:
				_last_sent_pos = cur_pos
				_send_brush_update(cur_pos)
