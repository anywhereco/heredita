## A container of constants.
class_name Statics
extends Object

static var HEREDITA_URL := "https://beta-drc.heredita.net"
static var SERVER_URL := "wss://beta-drc-gs.heredita.net"

static func initialize() -> void:
	var user_args := OS.get_cmdline_user_args()
	for i in range(user_args.size()):
		if user_args[i].contains("--heredita-url="):
			HEREDITA_URL = user_args[i].split("=")[1]
		if user_args[i].contains("--gameserver-url="):
			SERVER_URL = user_args[i].split("=")[1]
