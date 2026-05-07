class_name UserEnums

enum Rank { PLAYER, MODERATOR, ADMIN, DEV }


static func rank_to_string(rank: Rank) -> String:
	match rank:
		Rank.PLAYER:
			return "player"
		Rank.MODERATOR:
			return "moderator"
		Rank.ADMIN:
			return "administrator"
		Rank.DEV:
			return "developer"
		_:
			printerr("Unknown rank: %s" % [rank])
			return "player"


static func string_to_rank(rank_str: String) -> Rank:
	match rank_str.to_lower():
		"player":
			return Rank.PLAYER
		"moderator":
			return Rank.MODERATOR
		"administrator":
			return Rank.ADMIN
		"developer":
			return Rank.DEV
		_:
			printerr("Unknown rank string: %s" % [rank_str])
			return Rank.PLAYER


static func variant_to_rank(variant: Variant) -> Rank:
	if typeof(variant) == TYPE_STRING:
		@warning_ignore("unsafe_call_argument")
		return string_to_rank(variant)
	elif typeof(variant) == TYPE_INT:
		if variant in Rank.values():
			return variant
		else:
			printerr("Unknown rank int: %s" % [variant])
			return Rank.PLAYER
	else:
		printerr("Invalid rank variant type: %s" % [typeof(variant)])
		return Rank.PLAYER
