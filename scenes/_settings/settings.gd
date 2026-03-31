extends TabContainer

func make_slider(setting_data: SliderSetting) -> Control:
	var node: Control = preload("res://scenes/_settings/slider.tscn").instantiate()
	var slider: Control = node.find_child("Slider")
	
	if setting_data.is_log():
		slider.min_value = Math.log10(setting_data.min_value)
		slider.max_value = Math.log10(setting_data.max_value)
		slider.value = Math.log10(setting_data.default)
	else:
		slider.min_value = setting_data.min_value
		slider.max_value = setting_data.max_value
		slider.value = setting_data.default
		
	slider.step = (slider.max_value - slider.min_value) / 50.0
	if setting_data.snap != -1:
		slider.step = setting_data.snap
		
	node.percent = setting_data.is_percent()
	node.log10 = setting_data.is_log()
	return node


func make_toggle(_setting_data: ToggleSetting) -> Control:
	var node: Control = preload("res://scenes/_settings/toggle.tscn").instantiate()
	return node


func make_dropdown(setting_data: DropdownSetting) -> Control:
	var node: Control = preload("res://scenes/_settings/dropdown.tscn").instantiate()
	var dropdown: Control = node.find_child("Value")
	for option in setting_data.options:
		dropdown.add_item(option)
	return node


func tab_add_setting(tab: Container, setting: StringName, setting_data: SettingsResource) -> void:
	var setting_node: Control
	
	if setting_data is SliderSetting:
		@warning_ignore("unsafe_call_argument")
		setting_node = make_slider(setting_data)
	elif setting_data is ToggleSetting:
		@warning_ignore("unsafe_call_argument")
		setting_node = make_toggle(setting_data)
	elif setting_data is DropdownSetting:
		@warning_ignore("unsafe_call_argument")
		setting_node = make_dropdown(setting_data)
	else:
		push_error("Cannot make setting node for type %s" % setting_data.get_class())
		return

	setting_node.setting = Settings.get_reactive(setting)
	
	var setting_label: Label = preload("res://scenes/_settings/setting_label.tscn").instantiate()
	setting_label.text = setting_data.label
	tab.add_child(setting_label)
	tab.add_child(setting_node)


func _ready() -> void:
	var data: SettingsHolder = Settings.settings_data
	
	for tab in data.categories:
		var tab_node := GridContainer.new()
		tab_node.columns = 2
		tab_node.name = tab
		
		for setting: StringName in data.settings_order:
			if not data.settings.has(setting):
				continue
				
			var setting_data: SettingsResource = data.settings[setting]
			if not setting_data:
				continue
			
			var cat := setting_data.category if setting_data.category else &"Uncategorized"
			
			if cat == tab:
				tab_add_setting(tab_node, setting, setting_data)
		
		if tab_node.get_child_count() > 0:
			add_child(tab_node)
		else:
			tab_node.queue_free()
