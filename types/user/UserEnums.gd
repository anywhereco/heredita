class_name UserEnums

enum Rank {
	PLAYER,
	MODERATOR,
	ADMIN,
	DEV
}

static func rank_to_string(rank: Rank) -> String:
	match rank:
		Rank.PLAYER:
			return "Player"
		Rank.MODERATOR:
			return "Moderator"
		Rank.ADMIN:
			return "Admin"
		Rank.DEV:
			return "Developer"
		_:
			printerr("Unknown rank: %s" % [rank])
			return "Unknown"

static func string_to_rank(rank_str: String) -> Rank:
	match rank_str.to_lower():
		"player":
			return Rank.PLAYER
		"moderator":
			return Rank.MODERATOR
		"admin", "administrator":
			return Rank.ADMIN
		"developer":
			return Rank.DEV
		_:
			printerr("Unknown rank string: %s" % [rank_str])
			return Rank.PLAYER
