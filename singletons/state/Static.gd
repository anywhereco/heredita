## A container of constants.
class_name Statics
extends Object

static var HEREDITA_URL := "https://app.heredita.net"
static var SERVER_URL := "wss://gameserver.heredita.net"

const CHUNK_SIZE: int = 256
const CHUNK_SIZE_FLOAT: float = float(CHUNK_SIZE)


static func initialize() -> void:
	var user_args := OS.get_cmdline_user_args()
	for i in range(user_args.size()):
		if user_args[i].contains("--heredita-url="):
			HEREDITA_URL = user_args[i].split("=")[1]
		if user_args[i].contains("--gameserver-url="):
			SERVER_URL = user_args[i].split("=")[1]
