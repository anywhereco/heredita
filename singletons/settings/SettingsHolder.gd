@tool
class_name SettingsHolder
extends Resource

@export var categories: Array[StringName]
@export var settings: Dictionary[StringName, SettingsResource]
@export var settings_order: Array[StringName] 

## Dictionary[StringName category, Dictionary[StringName id, SettingsResource]]
var category_map: Dictionary[StringName, Dictionary]

func cache_mappings() -> void:
	category_map.clear()
	for cat in categories:
		category_map[cat] = {}
		
	var new_order: Array[StringName] =[]
	for key in settings_order:
		if settings.has(key): new_order.append(key)
	for key in settings:
		if not new_order.has(key): new_order.append(key)
	
	if new_order != settings_order:
		settings_order = new_order
		
	for key in settings_order:
		var res := gets(key)
		if not res: continue
		
		var cat := res.category if res.category else &"Uncategorized"
		if not categories.has(cat):
			categories.append(cat)
			category_map[cat] = {}
			
		category_map[cat][key] = res

func gets(key: StringName) -> SettingsResource:
	return settings.get(key)

# --- NATIVE INLINE INSPECTOR MAGIC ---

func _get_property_list() -> Array[Dictionary]:
	var props: Array[Dictionary] =[]
	var cats_to_draw := categories.duplicate()
	for key in settings:
		var res := settings[key]
		var cat := res.category if res else &"Uncategorized"
		if not cats_to_draw.has(cat): cats_to_draw.append(cat)
			
	for cat: StringName in cats_to_draw:
		props.append({
			"name": cat,
			"type": TYPE_NIL,
			"usage": PROPERTY_USAGE_GROUP,
			"hint_string": ""
		})
		
		for key in settings_order:
			var res := gets(key)
			var res_cat := res.category if res else &"Uncategorized"
			if res_cat == cat:
				props.append({
					"name": key, 
					"type": TYPE_OBJECT,
					"hint": PROPERTY_HINT_RESOURCE_TYPE,
					"hint_string": "SettingsResource",
					"usage": PROPERTY_USAGE_EDITOR
				})
	return props

func _set(property: StringName, value: Variant) -> bool:
	if settings.has(property):
		var new_settings := settings.duplicate()
		new_settings[property] = value
		settings = new_settings
		
		emit_changed()
		return true
	return false

func _get(property: StringName) -> Variant:
	if settings.has(property):
		return settings.get(property)
	return null
