extends Button


func _pressed() -> void:
	MainMenuForeground._instance.swap_page(MainMenuForeground.Page.MPTEST)
