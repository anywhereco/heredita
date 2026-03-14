class_name ErrorLabelForLogin
extends Label

var tween: Tween

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta: float) -> void:
	pass


func err(message: String) -> void:
	self.text = message
	self.modulate = Color.WHITE
	if tween:
		tween.kill()
	tween = create_tween().set_ease(Tween.EASE_IN).set_trans(Tween.TRANS_QUINT)
	tween.tween_property(self, "modulate", Color.TRANSPARENT, maxf(5, len(message) / 15.0))
