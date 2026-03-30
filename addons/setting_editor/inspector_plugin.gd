@tool
extends EditorInspectorPlugin

var plugin: EditorPlugin

func _init(_plugin: EditorPlugin) -> void:
	plugin = _plugin

func _can_handle(object: Object) -> bool:
	return object is SettingsHolder

func _parse_begin(object: Object) -> void:
	var holder = object as SettingsHolder
	var vbox = VBoxContainer.new()
	
	var header = HBoxContainer.new()
	header.alignment = BoxContainer.ALIGNMENT_CENTER
	var refresh_btn = Button.new()
	refresh_btn.text = "Refresh Grouping"
	refresh_btn.pressed.connect(func():
		holder.cache_mappings()
		holder.emit_changed()
		holder.notify_property_list_changed()
	)
	header.add_child(refresh_btn)
	
	header.add_spacer(false)
	
	var add_btn = Button.new()
	add_btn.text = "+ Add New Setting"
	add_btn.pressed.connect(func():
		var base_name = "new_setting"
		var i = 1
		var key = StringName(base_name)
		while holder.settings.has(key):
			key = StringName(base_name + "_" + str(i))
			i += 1
			
		var new_dict = holder.settings.duplicate()
		new_dict[key] = null
		
		var new_order = holder.settings_order.duplicate()
		new_order.append(key)
		
		_commit_action(holder, "Add New Setting", new_dict, new_order)
	)
	header.add_child(add_btn)
	
	vbox.add_child(header)
	vbox.add_child(HSeparator.new())
	add_custom_control(vbox)

func _parse_property(object: Object, type: Variant.Type, name: String, hint_type: PropertyHint, hint_string: String, usage_flags: int, wide: bool) -> bool:
	if name in ["settings", "categories", "category_map", "settings_order"]:
		return true 
		
	var holder = object as SettingsHolder
	var key = StringName(name)
	
	if holder.settings.has(key):
		var panel = PanelContainer.new()
		var style = StyleBoxFlat.new()
		style.bg_color = Color(0.15, 0.15, 0.15, 0.3)
		style.content_margin_left = 6
		style.content_margin_top = 4
		style.content_margin_bottom = 4
		panel.add_theme_stylebox_override("panel", style)

		var hbox = HBoxContainer.new()
		var label = Label.new()
		label.text = "Dict Key: "
		label.modulate = Color(0.6, 0.6, 0.6)
		
		var key_edit = LineEdit.new()
		key_edit.text = key
		key_edit.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		key_edit.text_submitted.connect(func(new_text):
			var new_key = StringName(new_text)
			if new_key in["settings", "categories", "category_map", "settings_order"]: return
			if new_key == key or new_key.is_empty() or holder.settings.has(new_key): return
			
			var new_dict = holder.settings.duplicate()
			new_dict[new_key] = new_dict[key]
			new_dict.erase(key)
			
			var new_order = holder.settings_order.duplicate()
			var idx = new_order.find(key)
			if idx != -1: new_order[idx] = new_key
			
			_commit_action(holder, "Rename Setting Key", new_dict, new_order)
		)
		
		var up_btn = Button.new()
		up_btn.text = "↑"
		up_btn.pressed.connect(func(): _move_key(holder, key, -1))
		
		var dn_btn = Button.new()
		dn_btn.text = "↓"
		dn_btn.pressed.connect(func(): _move_key(holder, key, 1))
		
		var del_btn = Button.new()
		del_btn.text = "X"
		del_btn.modulate = Color(1, 0.4, 0.4)
		del_btn.pressed.connect(func():
			var new_dict = holder.settings.duplicate()
			new_dict.erase(key)
			
			var new_order = holder.settings_order.duplicate()
			new_order.erase(key)
			
			_commit_action(holder, "Delete Setting Key", new_dict, new_order)
		)
		
		hbox.add_child(label)
		hbox.add_child(key_edit)
		hbox.add_child(up_btn)
		hbox.add_child(dn_btn)
		hbox.add_child(del_btn)
		panel.add_child(hbox)
		
		add_custom_control(panel)
		return false

	return false

func _move_key(holder: SettingsHolder, key: StringName, dir: int):
	var new_order = holder.settings_order.duplicate()
	var idx = new_order.find(key)
	if idx == -1: return
	
	var res = holder.settings.get(key)
	var cat = res.category if res and res.category else &"Uncategorized"
	
	var target_idx = -1
	var curr_idx = idx + dir
	
	while curr_idx >= 0 and curr_idx < new_order.size():
		var other_key = new_order[curr_idx]
		var other_res = holder.settings.get(other_key)
		var other_cat = other_res.category if other_res and other_res.category else &"Uncategorized"
		
		if other_cat == cat:
			target_idx = curr_idx
			break
			
		curr_idx += dir
	
	if target_idx == -1:
		return
	
	var temp = new_order[target_idx]
	new_order[target_idx] = key
	new_order[idx] = temp
	
	_commit_action(holder, "Move Setting Order", holder.settings.duplicate(), new_order)


func _commit_action(holder: SettingsHolder, action_name: String, new_dict: Dictionary, new_order: Array) -> void:
	var ur = plugin.get_undo_redo()
	ur.create_action(action_name)
	
	ur.add_do_property(holder, "settings", new_dict)
	ur.add_do_property(holder, "settings_order", new_order)
	ur.add_do_method(holder, "cache_mappings")
	ur.add_do_method(holder, "notify_property_list_changed")
	
	ur.add_undo_property(holder, "settings", holder.settings.duplicate())
	ur.add_undo_property(holder, "settings_order", holder.settings_order.duplicate())
	ur.add_undo_method(holder, "cache_mappings")
	ur.add_undo_method(holder, "notify_property_list_changed")
	
	ur.commit_action()
