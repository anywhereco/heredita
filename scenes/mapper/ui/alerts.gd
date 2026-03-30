extends HBoxContainer

@onready var lock_message: Label = $LockMessage
@onready var resyncing_message: Label = $ResyncingMessage

var resyncing_tween: Tween

@onready var player: PlayerMovement = MapperRoot._instance.get_node("LocalPlayer")


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	if player:
		player.camera.topdown_camera.value_changed.connect(_lock_unlock)
	if Map._instance:
		Map._instance.pending_resync.value_changed.connect(_resyncing)


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta: float) -> void:
	pass


func _lock_unlock(val: ReactiveBool) -> void:
	if val.value:
		lock_message.show()
	else:
		lock_message.hide()


func _resyncing(val: ReactiveBool) -> void:
	if val.value:
		resyncing_message.show()
		resyncing_tween = create_tween().set_ease(Tween.EASE_IN_OUT).set_trans(Tween.TRANS_SINE).set_loops()
		resyncing_tween.tween_property(resyncing_message, "modulate", Color(.7, .7, .7, 1), .667)
		resyncing_tween.tween_property(resyncing_message, "modulate", Color(1, 1, 1, 1), .667)
	elif resyncing_tween:
		resyncing_tween.kill()
		resyncing_message.modulate = Color(1, 1, 1, 1)
		resyncing_message.hide()
