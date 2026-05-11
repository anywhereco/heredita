extends Button


func _pressed() -> void:
	if State.client:
		#open dialog box
		State.client.send("change_rp_name")
