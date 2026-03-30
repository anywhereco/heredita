@tool
extends EditorInspectorPlugin

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
		holder.settings = new_dict
		
		var new_order = holder.settings_order.duplicate()
		new_order.append(key)
		holder.settings_order = new_order
		
		holder.emit_changed()
		holder.notify_property_list_changed()
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
			holder.settings = new_dict
			
			var new_order = holder.settings_order.duplicate()
			var idx = new_order.find(key)
			if idx != -1: new_order[idx] = new_key
			holder.settings_order = new_order
			
			holder.emit_changed()
			holder.notify_property_list_changed()
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
			holder.settings = new_dict
			
			var new_order = holder.settings_order.duplicate()
			new_order.erase(key)
			holder.settings_order = new_order
			
			holder.emit_changed()
			holder.notify_property_list_changed()
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
	
	var target = idx + dir
	if target < 0 or target >= new_order.size(): return
	
	var temp = new_order[target]
	new_order[target] = key
	new_order[idx] = temp
	
	holder.settings_order = new_order
	holder.emit_changed()
	holder.notify_property_list_changed()
