extends HBoxContainer

@onready var lock_message: Label = $LockMessage

@onready var player: PlayerMovement = MapperRoot._instance.get_node("LocalPlayer")

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	if player:
		player.camera.topdown_camera.value_changed.connect(_lock_unlock)

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta: float) -> void:
	pass

func _lock_unlock(val: ReactiveBool) -> void:
	if val.value:
		lock_message.show()
	else:
		lock_message.hide()
