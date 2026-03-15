extends HScrollBar
@onready var bar: ScrollContainer = %TabScroll as ScrollContainer


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	var scroll := bar.get_h_scroll_bar()
	scroll.share(self)


func _process(_delta: float) -> void:
	if max_value == page:
		hide()
	else:
		show()
