extends Node

const SAVE_PATH: String = "user://settings.cfg"

var settings_data: SettingsHolder = preload("uid://dbu2ny70g7vwj")

var settings: ReactiveDictionary = ReactiveDictionary.new({})


func getv(setting: String, fallback: Variant = null) -> Variant:
	if settings.has(setting):
		return settings.getv(setting).value
	if fallback == null:
		return settings_data.gets(setting).default
	return fallback


func getv_strict(setting: String) -> Variant:
	return settings.getv(setting).value


func get_reactive(setting: String) -> Reactive:
	return settings.getv(setting)


func _init() -> void:
	settings_data.cache_mappings()
	_load_settings()
	for setting in settings_data.settings:
		if settings.has(setting):
			continue
		
		var res := settings_data.gets(setting)
		if res is SliderSetting:
			@warning_ignore("unsafe_call_argument")
			settings.setv(setting, ReactiveFloat.new(res.default))
		elif res is ToggleSetting:
			@warning_ignore("unsafe_call_argument")
			settings.setv(setting, ReactiveBool.new(res.default))
		elif res is DropdownSetting:
			@warning_ignore("unsafe_call_argument")
			settings.setv(setting, ReactiveInt.new(res.default))
			
	settings.value_changed.connect(_save_settings.unbind(1))

func _ready() -> void:
	pass


func _load_settings() -> bool:
	settings = ReactiveDictionary.new({})
	var config := ConfigFile.new()
	var err := config.load(SAVE_PATH)
	if err:
		return err
	for category in settings_data.categories:
		for setting: StringName in settings_data.category_map[category]:
			var value: Variant = config.get_value(category, setting)
			if value == null:
				var res := settings_data.gets(setting)
				if res is SliderSetting:
					@warning_ignore("unsafe_call_argument")
					settings.setv(setting, ReactiveFloat.new(res.default))
				elif res is ToggleSetting:
					@warning_ignore("unsafe_call_argument")
					settings.setv(setting, ReactiveBool.new(res.default))
				elif res is DropdownSetting:
					@warning_ignore("unsafe_call_argument")
					settings.setv(setting, ReactiveInt.new(res.default))
				continue
			if typeof(value) == TYPE_BOOL:
				@warning_ignore("unsafe_call_argument")
				value = ReactiveBool.new(value)
			if typeof(value) == TYPE_FLOAT:
				@warning_ignore("unsafe_call_argument")
				value = ReactiveFloat.new(value)
			if typeof(value) == TYPE_INT:
				@warning_ignore("unsafe_call_argument")
				value = ReactiveInt.new(value)
			settings.setv(setting, value)
			
	return OK


func _save_settings() -> Error:
	var config := ConfigFile.new()
	for category in settings_data.categories:
		for setting: StringName in settings_data.category_map[category]:
			config.set_value(category, setting, settings.getv(setting).value)
	return config.save(SAVE_PATH)
