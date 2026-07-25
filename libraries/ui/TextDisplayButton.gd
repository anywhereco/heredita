class_name TextDisplayButton
extends Button

## nullable
var panel: PanelContainer = null
var tween: Tween = null

## The amount of seconds to persist before hiding.
@export var persistence_time: float = 10.0
## The text to show.
@export var text_to_show: String = ""

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.


func _toggled(toggled_on: bool) -> void:
	if tween != null:
		tween.kill()
	if toggled_on:
		if panel != null:
			panel.queue_free()
		_create_tooltip_box()
		tween = create_tween().set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_QUART)
		tween.tween_property(panel, "position", panel.position + Vector2(0, -10), 0.2)
		tween.parallel().tween_property(panel, "modulate", Color.WHITE, 0.2)
		tween.tween_interval(persistence_time)
		tween.tween_callback(self.pressed.emit)
		tween.tween_property(self, "button_pressed", false, 0)
		tween.tween_callback(self._toggled.bind(false))
		panel.show()
	else:
		if panel == null:
			return
		tween = create_tween().set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_QUART)
		tween.tween_property(panel, "position", panel.position - Vector2(0, -10), 0.2)
		tween.parallel().tween_property(panel, "modulate", Color.TRANSPARENT, 0.2)
		tween.tween_callback(panel.queue_free)



func _create_tooltip_box() -> PanelContainer:
	var pc := PanelContainer.new()
	pc.theme_type_variation = &"TooltipPanel"
	pc.modulate = Color.TRANSPARENT
	var label := Label.new()
	label.theme_type_variation = &"TooltipLabel"
	label.text = tr(text_to_show)
	pc.add_child(label)
	add_child(pc)
	pc.position += Vector2(0, 5)
	pc.position -= Vector2(pc.size.x / 2, pc.size.y)
	panel = pc
	return pc
