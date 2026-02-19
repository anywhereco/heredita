extends Button


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _pressed() -> void:
	print(Prompts.prompts)
	print(Prompts.close_prompt(Prompts.prompts.size()-1))
