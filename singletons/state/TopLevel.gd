extends Node

var ui: Node

func get_ui() -> Node:
	var top_ui: Node
	if ui != null:
		top_ui = ui
	else:
		for child in $/root.get_children():
			if child is Control: # top-level ui node
				top_ui = child
				break
	return top_ui #can be null
