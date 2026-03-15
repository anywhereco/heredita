extends Button

@onready var foreground: MainMenuForeground = MainMenuForeground._instance


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass  # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _pressed() -> void:
	foreground.swap_page(MainMenuForeground.Page.LANDING)
