extends Button

@export var create: bool = false


func enter_mapper() -> void:
	const MAPPER_3D = preload("uid://bmfinmmve5h47")
	var mapper: MapperRoot = MAPPER_3D.instantiate()
	get_tree().current_scene.queue_free()
	get_tree().root.add_child(mapper)
	get_tree().current_scene = mapper
	#VirtualMouse._instance.enabled = true


func _pressed() -> void:
	if create:
		State.client = InfernoSocketClientTemp.new(Statics.SERVER_URL, 0, {"name": "Testers' Room"})
	else:
		State.client = InfernoSocketClientTemp.new(Statics.SERVER_URL, 0)
	get_tree().root.add_child(State.client)
	State.client.handshake_complete.connect(enter_mapper)
