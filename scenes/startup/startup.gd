extends Node

func _ready() -> void:
	if "--server" in OS.get_cmdline_user_args():
		get_tree().change_scene_to_file.call_deferred("res://server/Server.tscn")
	else:
		get_tree().change_scene_to_file.call_deferred("res://scenes/main_menu/main.tscn")
