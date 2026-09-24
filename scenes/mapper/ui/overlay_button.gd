extends MenuButton

const FILE_OVERLAY = preload("uid://cqnebsifeyeex")
const OPENFOLDER = preload("uid://btb4jabo6nmoe")


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	get_popup().id_pressed.connect(click_item)
	if State.player.privileged():
		get_popup().add_icon_item(OPENFOLDER, tr("mapper/overlay.load"), -1)
	else:
		get_popup().add_icon_item(OPENFOLDER, tr("mapper/overlay.load_local"), -1)
	get_popup().add_icon_item(FILE_OVERLAY, "Overlay 1", -1)

func click_item(id: int) -> void:
	pass
