extends Label

func _ready() -> void:
	text = Engine.get_license_text()
