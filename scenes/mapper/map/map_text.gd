class_name MapText
extends Node3D

signal changed(id: String)

@onready var map: Map = get_parent()

var data := MapTextData.new()
var labels: Dictionary[String, MapTextLabel] = {}


func set_texts(texts: MapTextData) -> void:
	data = MapTextData.new()
	data.load_labels(texts.serialize(), map.original_map_size)
	for label: MapTextLabel in labels.values():
		label.queue_free()
	labels.clear()
	rebuild()
	changed.emit("")


func rebuild() -> void:
	for label: Dictionary in data.labels.values():
		preview_label(label)


func apply_update(details: Dictionary) -> bool:
	if not data.apply_update(details, map.original_map_size):
		return false
	var id: String = details["id"]
	if data.labels.has(id):
		preview_label(data.labels[id])
	else:
		remove_label(id)
	changed.emit(id)
	return true


func preview_label(label: Dictionary) -> void:
	var id: String = label["id"]
	if not labels.has(id):
		var node := MapTextLabel.new()
		labels[id] = node
		add_child(node)
	labels[id].update_label(label, map)


func remove_label(id: String) -> void:
	if labels.has(id):
		labels[id].queue_free()
		labels.erase(id)


func get_at_position(pixel: Vector2, margin: float) -> String:
	var closest := ""
	var distance := INF
	for id: String in data.labels:
		if not labels.has(id):
			continue
		var hit := labels[id].hit_distance(pixel, margin)
		if hit < distance:
			distance = hit
			closest = id
	return closest
