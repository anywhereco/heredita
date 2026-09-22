## A container of constants.
class_name Statics
extends Object

static var HEREDITA_URL := "https://app.heredita.net"
static var SERVER_URL := "wss://gameserver.heredita.net"
## May be empty
static var S2S_KEY := ""

const CHUNK_SIZE: int = 256
const CHUNK_SIZE_FLOAT: float = float(CHUNK_SIZE)


static func initialize() -> void:
	if OS.has_feature("debug"):
		HEREDITA_URL = "http://127.0.0.1:9000"
		SERVER_URL = "ws://127.0.0.1:9001"
	var user_args := OS.get_cmdline_user_args()
	S2S_KEY = OS.get_environment("HEREDITA_S2S_KEY")
	for i in range(user_args.size()):
		if user_args[i].contains("--heredita-url="):
			HEREDITA_URL = user_args[i].split("=")[1]
		if user_args[i].contains("--gameserver-url="):
			SERVER_URL = user_args[i].split("=")[1]
		if user_args[i].contains("--s2s-key="):
			S2S_KEY = user_args[i].split("=")[1]
