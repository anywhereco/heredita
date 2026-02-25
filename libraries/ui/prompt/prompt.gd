extends PanelContainer
class_name PromptInstance

signal prompt_closed

var idx := -1
var closeable := true

@onready
var blur: ColorRect = self.get_parent().get_parent() as ColorRect

func _input(event: InputEvent) -> void:
	var mouseEvent := event as InputEventMouseButton
	if mouseEvent is InputEventMouseButton and mouseEvent.is_pressed() and mouseEvent.button_index == 1:
		var evLocal := make_input_local(mouseEvent) as InputEventMouseButton 
		if closeable and idx == Prompts.prompts.size() - 1 and not Prompts.prompt_already_closed and not Rect2(Vector2(0,0), size).has_point(evLocal.position):
			close()
			
func _unhandled_input(_event: InputEvent) -> void:
	get_viewport().set_input_as_handled()

func close() -> void:
	Prompts.prompt_already_closed = true
	prompt_closed.emit()
	blur.queue_free()
	if Prompts.prompts.size() <= 1:
		Prompts.in_prompt = false
	Prompts.prompts.remove_at(idx)

func make_uncloseable() -> void:
	closeable = false

func hide_prompt() -> void:
	blur.hide()

func show_prompt() -> void:
	blur.show()
	
func hide_panel() -> void:
	theme_type_variation = &"HiddenPanel"
	
func show_panel() -> void:
	theme_type_variation = &"Prompt"
