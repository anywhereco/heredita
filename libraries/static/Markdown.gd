class_name Markdown


static func bb_escape(bbcode_text: String) -> String:  #technically not a markdown function but theres no better place to put it
	return bbcode_text.replace("[", "[lb]")

static func parse_markdown(text: String) -> Dictionary:
	var idx := 0
	var parsed := {t = "text", c = [""], p = null, i = null}  #type, content, parent
	var current_layer := parsed
	while idx < len(text):
		if text[idx] == "*":
			if current_layer.t == "italics":
				current_layer = current_layer.p
				current_layer.c.append("")
			else:
				current_layer.c.append(
					{t = "italics", c = [""], p = current_layer, i = len(current_layer.c)}
				)
				current_layer = current_layer.c[-1]
		else:
			current_layer.c[-1] += text[idx]
		idx += 1

	return parsed

#func display_markdown(label: RichTextLabel, markdown: Dictionary):
#	pass
