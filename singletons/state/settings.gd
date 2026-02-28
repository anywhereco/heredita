extends Node

const SAVE_PATH: String = "user://settings.json"

var settings: ReactiveDictionary = ReactiveDictionary.new({})
var settings_data: Dictionary[String, SettingsResource] = {
	"mouse_sensitivity": SliderSetting.new(
		"Mouse sensitivity",
		SliderSetting.Type.LOG_PERCENT,
		1.0,
		0.1,
		10
	),
	"camera_sensitivity": SliderSetting.new(
		"Camera sensitivity",
		SliderSetting.Type.LOG_PERCENT,
		1.0,
		0.1,
		10
	),
	"ui_scale": SliderSetting.new(
		"UI Scale",
		SliderSetting.Type.PERCENT,
		1.0,
		1.0,
		3.0, # TODO: we should probably cap this based on current screen size?
		0.25
	),
	"unfocus_on_chat_submission": ToggleSetting.new(
		"Unfocus on chat send",
		true
	),
	"enable_seconds": ToggleSetting.new(
		"Enable seconds in time",
		false
	)
}
var settings_tabs: Dictionary[String, Array] = {
	"Input": [
		"mouse_sensitivity"
	],
	"Game": [
		"camera_sensitivity",
		"unfocus_on_chat_submission",
		"enable_seconds"
	],
	"UI": [
		"ui_scale"
	]
}



func getv(setting: String, fallback: Variant = null) -> Variant:
	if settings.has(setting):
		return settings.getv(setting).value
	if fallback == null:
		return settings_data[setting].default
	return fallback

func getv_strict(setting: String) -> Variant:
	return settings.getv(setting).value

func get_reactive(setting: String) -> Reactive:
	return settings.getv(setting)

func _init() -> void:
	_load_settings()
	for setting in settings_data:
		if settings.has(setting):
			continue
		if settings_data.get(setting) is SliderSetting:
			settings.setv(setting, ReactiveFloat.new((settings_data[setting] as SliderSetting).default))
		if settings_data.get(setting) is ToggleSetting:
			settings.setv(setting, ReactiveBool.new((settings_data[setting] as ToggleSetting).default))
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
		settings = ReactiveDictionary.new(reactive_convert(JSON.to_native(JSON.parse_string(file.get_as_text()))))
	return file != null
	
func _save_settings() -> void:
	var file := FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	file.store_string(JSON.stringify(JSON.from_native(reactive_unconvert(settings.value))))
