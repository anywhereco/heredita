extends VBoxContainer

var reactive_map: ReactiveMapData
var _updating := false

@onready var count: Label = $CountContainer/Count
@onready var hwrap_check: CheckBox = $HWrapContainer/HWrapCheck
@onready var vwrap_check: CheckBox = $VWrapContainer/VWrapCheck

func _ready() -> void:
	if not hwrap_check.toggled.is_connected(_on_hwrap_value_changed):
		hwrap_check.toggled.connect(_on_hwrap_value_changed)
	if not vwrap_check.toggled.is_connected(_on_vwrap_value_changed):
		vwrap_check.toggled.connect(_on_vwrap_value_changed)


func setup(map: ReactiveMapData) -> void:
	reactive_map = map
	if not reactive_map.value_changed.is_connected(_on_map_changed):
		reactive_map.value_changed.connect(_on_map_changed)
	_update_from_map()


func _on_map_changed(_new_map: ReactiveMapData) -> void:
	_update_from_map()


func _update_from_map() -> void:
	if reactive_map == null:
		return
	_updating = true
	hwrap_check.button_pressed = reactive_map.value.hwrap
	vwrap_check.button_pressed = reactive_map.value.vwrap
	_updating = false

func _on_hwrap_value_changed(enabled: bool) -> void:
	if _updating:
		return
	if reactive_map != null:
		reactive_map.value.hwrap = enabled
		
func _on_vwrap_value_changed(enabled: bool) -> void:
	if _updating:
		return
	if reactive_map != null:
		reactive_map.value.vwrap = enabled
