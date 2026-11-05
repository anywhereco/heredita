class_name MapOverlays
extends Node3D

signal changed

@onready var map: Map = get_parent()

var global_data := MapOverlayData.new()
var local_data := MapOverlayData.new()
# Personal display choices never enter MapData or the network.
var display_settings: Dictionary[String, Dictionary] = {}
var sprites: Dictionary[String, Sprite3D] = {}


func set_globals(data: MapOverlayData) -> void:
	global_data = MapOverlayData.new()
	global_data.overlays = data.overlays.duplicate(true)
	for id: String in sprites.keys():
		if local_data.overlays.has(id) and not global_data.overlays.has(id):
			continue
		_remove_sprite(id)
		if not global_data.overlays.has(id):
			display_settings.erase(id)
	rebuild()
	changed.emit()


func apply_update(details: Dictionary, local: bool = false) -> bool:
	var data := local_data if local else global_data
	if not data.apply_update(details):
		return false
	var id: String = details["id"]
	if not data.overlays.has(id):
		_remove_sprite(id)
		display_settings.erase(id)
	rebuild()
	changed.emit()
	return true


func rebuild() -> void:
	var layer := 0
	for data: MapOverlayData in [global_data, local_data]:
		for overlay: Dictionary in data.overlays.values():
			var id: String = overlay["id"]
			if not sprites.has(id):
				var image := MapOverlayData.image_from_buffer(overlay["image"] as PackedByteArray)
				if image == null:
					continue
				var sprite := Sprite3D.new()
				sprite.texture = ImageTexture.create_from_image(image)
				sprite.axis = Vector3.AXIS_Y
				sprite.shaded = false
				# Chunks and overlays are transparent sprites, so depth sorting alone is insufficient.
				sprite.render_priority = 1
				sprite.double_sided = false
				sprite.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
				sprites[id] = sprite
				add_child(sprite)
			var sprite := sprites[id]
			sprite.texture_filter = BaseMaterial3D.TEXTURE_FILTER_NEAREST if overlay.get("filter", MapOverlayData.DEFAULT_FILTER) == "nearest" else BaseMaterial3D.TEXTURE_FILTER_LINEAR
			sprite.position = Vector3(0, 0.005 + layer * 0.00001, 0)
			sprite.pixel_size = map.pixel_size
			var size := map.original_map_size
			var texture_size := sprite.texture.get_size()
			sprite.scale = Vector3(size.x / texture_size.x, 1.0, size.y / texture_size.y)
			_update_display(id)
			layer += 1


func overlay_for(id: String) -> Dictionary:
	return local_data.overlays.get(id, global_data.overlays.get(id, {}))


func opacity_for(id: String) -> float:
	return float(display_settings.get(id, {}).get("opacity", overlay_for(id).get("opacity", 1.0)))


func visible_for(id: String) -> bool:
	return bool(display_settings.get(id, {}).get("visible", true))


func set_display(id: String, opacity: float, shown: bool) -> void:
	display_settings[id] = {"opacity": clampf(opacity, 0.0, 1.0), "visible": shown}
	_update_display(id)


func reset_display(id: String) -> void:
	display_settings.erase(id)
	_update_display(id)


func _update_display(id: String) -> void:
	if sprites.has(id):
		sprites[id].modulate = Color(1, 1, 1, opacity_for(id))
		sprites[id].visible = visible_for(id)


func _remove_sprite(id: String) -> void:
	if sprites.has(id):
		sprites[id].queue_free()
		sprites.erase(id)
