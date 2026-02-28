extends TabContainer

func make_slider(setting_data: SliderSetting, percent := false, log10 := false) -> Control:
	var node: Control = preload("res://scenes/_settings/slider.tscn").instantiate()
	var slider: Control = node.find_child("Slider")
	if log10:
		slider.min_value = Math.log10(setting_data.min_value)
		slider.max_value = Math.log10(setting_data.max_value)
		slider.value = Math.log10(setting_data.default)
	else:
		slider.min_value = setting_data.min_value
		slider.max_value = setting_data.max_value
		slider.value = setting_data.default
	slider.step = (slider.max_value - slider.min_value)/50.0
	if setting_data.snap != -1:
		slider.step = setting_data.snap
	node.percent = percent
	node.log10 = log10
	return node

func make_toggle(_setting_data: ToggleSetting) -> Control:
	var node: Control = preload("res://scenes/_settings/toggle.tscn").instantiate()
	return node

func tab_add_setting(tab: Container, setting: String) -> void:
	var setting_data := Settings.settings_data[setting]
	var setting_node: Control
	match (setting_data.get_script() as Script).get_global_name():
		"SliderSetting":
			var slider := setting_data as SliderSetting
			setting_node = make_slider(slider, slider.is_percent(), slider.is_log())
		"ToggleSetting":
			var toggle := setting_data as ToggleSetting
			setting_node = make_toggle(toggle)
		_:
			push_error("Cannot make setting node for type %s" % (setting_data.get_script() as Script).get_global_name())
	setting_node.setting = Settings.get_reactive(setting)
	var setting_label: Label = preload("res://scenes/_settings/setting_label.tscn").instantiate()
	setting_label.text = setting_data.label
	tab.add_child(setting_label)
	tab.add_child(setting_node)

func _ready() -> void:
	for tab in Settings.settings_tabs:
		var tab_node := GridContainer.new()
		tab_node.columns = 2
		tab_node.name = tab
		for setting: String in Settings.settings_tabs[tab]:
			tab_add_setting(tab_node, setting)
		add_child(tab_node)
