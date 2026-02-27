@tool
extends Container
class_name BumpedPanelContainer
#Holds exactly 3 controls

##How much wider the bump is than its contents' minimum size.
##(The contents will expand to fill the bump.)
@export var bump_space: float = 5: 
	set(x): bump_space = x; queue_sort(); queue_redraw()
##How much taller the bump is than its contents' minimum size.
##(The contents will expand to fill the bump.)
@export var bump_protrusion: float = -10: 
	set(x): bump_protrusion = x; queue_sort(); queue_redraw()

var Left: Control
var Bump: Control
var Right: Control

func _update_children() -> void:
	Left = get_child(0)
	Bump = get_child(1)
	Right = get_child(2)
	
func _get_minimum_size() -> Vector2:
	_update_children()
	var x := (Left.get_combined_minimum_size() +
			  Bump.get_combined_minimum_size() +
			  Right.get_combined_minimum_size()).x
	var y := Left.get_combined_minimum_size().max(Right.get_combined_minimum_size()).y
	return Vector2(x,y)

func _notification(what: int) -> void:
	match what:
		NOTIFICATION_DRAW:
			var stylebox := get_theme_stylebox("panel", &"BumpedPanelContainer")
			var rect := Rect2(Vector2.ZERO, size)
			stylebox.draw(self.get_canvas_item(), rect)
			var bump_stylebox := get_theme_stylebox("bump", &"BumpedPanelContainer")
			var bump_size := Bump.get_combined_minimum_size() + Vector2(bump_space,bump_protrusion-size.y)
			var bump_rect := Rect2(size.x/2-bump_size.x/2, size.y, bump_size.x, bump_size.y)
			bump_stylebox.draw(self.get_canvas_item(), bump_rect)
		NOTIFICATION_SORT_CHILDREN:
			_update_children()
			var stylebox := get_theme_stylebox("panel", &"PanelContainer")
			var fit_size := get_size() - stylebox.get_minimum_size()
			var offset := stylebox.get_offset()
			var bump_size := Bump.get_combined_minimum_size() + Vector2(bump_space,bump_protrusion-size.y)
			fit_child_in_rect(Bump, Rect2(offset.x + fit_size.x/2 - bump_size.x/2, offset.y,
										  bump_size.x, bump_size.y))
			fit_child_in_rect(Left, Rect2(offset.x, offset.y,
										  fit_size.x - bump_size.x/2, fit_size.y))
			fit_child_in_rect(Right, Rect2(offset.x + fit_size.x/2 + bump_size.x/2, offset.y,
										   fit_size.x - bump_size.x/2, fit_size.y))
