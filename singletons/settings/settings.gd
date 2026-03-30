extends Node

const SAVE_PATH: String = "user://settings.json"

var settings_data: SettingsHolder = preload("uid://dbu2ny70g7vwj")

var settings: ReactiveDictionary = ReactiveDictionary.new({})


func getv(setting: String, fallback: Variant = null) -> Variant:
	if settings.has(setting):
		return settings.getv(setting).value
	if fallback == null:
		return settings_data.gets(setting).defaul
	return fallback


func getv_strict(setting: String) -> Variant:
	return settings.getv(setting).value


func get_reactive(setting: String) -> Reactive:
	return settings.getv(setting)


func _init() -> void:
	_load_settings()
	settings_data.cache_mappings()
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
			
	settings.value_changed.connect(_save_settings.unbind(1))

func _ready() -> void:
	pass


func reactive_convert(data: Dictionary) -> Dictionary:
	var new := {}
	for key: Variant in data.keys():
		new[key] = ReactiveHelper.convert(data[key])
	return new


func reactive_unconvert(data: Dictionary) -> Dictionary:
	var new := {}
	for key: Variant in data.keys():
		if data[key] is Reactive:
			new[key] = data[key].deep_unconvert()
		else:
			new[key] = data[key]
	return new


func _load_settings() -> bool:
	var file := FileAccess.open(SAVE_PATH, FileAccess.READ)
	if file:
		@warning_ignore("unsafe_call_argument")
		settings = ReactiveDictionary.new(
			reactive_convert(JSON.to_native(JSON.parse_string(file.get_as_text())))
		)
	return file != null


func _save_settings() -> void:
	var file := FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	file.store_string(JSON.stringify(JSON.from_native(reactive_unconvert(settings.value))))
