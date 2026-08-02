class_name MapMarkings
extends Node3D

@onready var map: Map = $".."

@onready var cities_mesh: MultiMeshInstance3D = $Cities
@onready var forts_mesh: MultiMeshInstance3D = $Forts
@onready var text_meshes: Node3D = $TextMeshes

const MAX_MARKINGS := 8192
const CITY_MESH_SCALE := 0.063
const FORT_MESH_SCALE := 0.22
const FORT_MESH_HEIGHT_SCALE := 0.08
const LABEL_VISIBLE_DISTANCE := 26.0
const LABEL_VISIBLE_DISTANCE_SQ := LABEL_VISIBLE_DISTANCE * LABEL_VISIBLE_DISTANCE
const LABEL_COLOR := Color(0.95, 0.95, 0.9)
const LABEL_OUTLINE_COLOR := Color(0.08, 0.08, 0.1)

var map_objects: Dictionary[String, MapObject] = {}
var labels: Dictionary[String, Label3D] = {}

@abstract class MapObject:
	var id: String
	var marking_type: String
	var name: String
	var position: Vector2
	var scale: float = 1.0
	var rotation: float = 0.0
	var color: Color
	var basis: Basis:
		get():
			return Basis.from_scale(get_mesh_scale() * scale).rotated(Vector3.UP, rotation)
	var transform: Transform3D:
		get():
			return Transform3D(basis, Vector3(position.x, 0.01, position.y))

	@abstract func is_in_bounds(other: Vector2) -> bool

	func get_mesh_scale() -> Vector3:
		return Vector3.ONE * CITY_MESH_SCALE

	func to_data(pixel_size: float) -> Dictionary:
		return {
			"id": id,
			"marking_type": marking_type,
			"position": ISUtil.from_vec2(position / pixel_size),
			"scale": scale,
			"rotation": rotation,
			"color": ISUtil.from_color(color),
			"name": name
		}

	static func from_data(data: Dictionary) -> MapObject:
		if not MapData._valid_serialized_marking(data):
			return null
		var object: MapObject
		if data["marking_type"] == "city":
			object = City.new()
		elif data["marking_type"] == "fort":
			object = Fort.new()
		else:
			return null
		object.id = data["id"]
		object.marking_type = data["marking_type"]
		@warning_ignore("unsafe_call_argument")
		object.position = ISUtil.to_vec2(data["position"])
		object.scale = data.get("scale", 1.0)
		object.rotation = data.get("rotation", 0.0)
		@warning_ignore("unsafe_call_argument")
		object.color = ISUtil.to_color(data["color"])
		object.name = data.get("name", "")
		return object


class City:
	extends MapObject

	func _init() -> void:
		marking_type = "city"

	func is_in_bounds(other: Vector2) -> bool:
		other -= position
		return other.length_squared() <= scale ** 2


class Fort:
	extends MapObject

	func _init() -> void:
		marking_type = "fort"

	func is_in_bounds(other: Vector2) -> bool:
		other -= position
		return abs(other.x) <= scale and abs(other.y) <= scale

	func get_mesh_scale() -> Vector3:
		return Vector3(FORT_MESH_SCALE, FORT_MESH_HEIGHT_SCALE, FORT_MESH_SCALE)


func _ready() -> void:
	var marker_material := StandardMaterial3D.new()
	marker_material.vertex_color_use_as_albedo = true
	marker_material.albedo_color = Color.WHITE
	marker_material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	cities_mesh.material_override = marker_material
	forts_mesh.material_override = marker_material
	cities_mesh.multimesh.instance_count = MAX_MARKINGS
	cities_mesh.multimesh.visible_instance_count = 0
	forts_mesh.multimesh.instance_count = MAX_MARKINGS
	forts_mesh.multimesh.visible_instance_count = 0


func set_markings(data: Array[Dictionary]) -> void:
	map_objects.clear()
	for label: Label3D in labels.values():
		label.queue_free()
	labels.clear()
	for marking: Dictionary in data:
		var object := MapObject.from_data(marking)
		object.position *= map.pixel_size
		if object:
			map_objects[object.id] = object
	rebuild()


func serialize_markings() -> Array[Dictionary]:
	var data: Array[Dictionary] = []
	for object: MapObject in map_objects.values():
		data.append(object.to_data(map.pixel_size))
	return data


func apply_update(details: Dictionary) -> void:
	var op: String = details.get("op", "")
	var id: String = details.get("id", "")
	if not MapData._valid_marking_id(id):
		return
	if op == "create":
		var object := MapObject.from_data(details)
		if object:
			map_objects[id] = object
	elif op == "delete":
		map_objects.erase(id)
	elif op == "edit" and map_objects.has(id):
		var object := map_objects[id]
		if details.has("color"):
			if not MapData._valid_color_array(details["color"]):
				return
			@warning_ignore("unsafe_call_argument")
			object.color = ISUtil.to_color(details["color"])
		if details.has("name"):
			if not MapData._valid_marking_name(details["name"]):
				return
			object.name = details["name"]
	rebuild()


@warning_ignore("shadowed_variable_base_class")
func get_at_position(position: Vector2, allowed_types: Array[String] = []) -> MapObject:
	var closest: MapObject = null
	var closest_dist := INF
	for object: MapObject in map_objects.values():
		if not allowed_types.is_empty() and not object.marking_type in allowed_types:
			continue
		if object.is_in_bounds(position):
			var dist := object.position.distance_squared_to(position)
			if dist < closest_dist:
				closest = object
				closest_dist = dist
	return closest


func rebuild() -> void:
	var city_idx := 0
	var fort_idx := 0
	var active_label_ids: Array[String] = []
	for object: MapObject in map_objects.values():
		if object.marking_type == "city" and city_idx < MAX_MARKINGS:
			cities_mesh.multimesh.set_instance_transform(city_idx, object.transform)
			cities_mesh.multimesh.set_instance_color(city_idx, object.color)
			city_idx += 1
		elif object.marking_type == "fort" and fort_idx < MAX_MARKINGS:
			forts_mesh.multimesh.set_instance_transform(fort_idx, object.transform)
			forts_mesh.multimesh.set_instance_color(fort_idx, object.color)
			fort_idx += 1
		if not object.name.is_empty():
			active_label_ids.append(object.id)
			_update_label(object)
	cities_mesh.multimesh.visible_instance_count = city_idx
	forts_mesh.multimesh.visible_instance_count = fort_idx

	var label_ids: Array = labels.keys()
	for id: String in label_ids:
		if not id in active_label_ids:
			labels[id].queue_free()
			labels.erase(id)


func _update_label(object: MapObject) -> void:
	var label: Label3D
	if labels.has(object.id):
		label = labels[object.id]
	else:
		label = Label3D.new()
		label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
		label.shaded = false
		label.no_depth_test = false
		label.fixed_size = false
		label.pixel_size = 0.01
		label.font_size = 36
		label.outline_size = 5
		label.render_priority = 2
		label.outline_render_priority = 1
		labels[object.id] = label
		text_meshes.add_child(label)
	label.text = object.name
	label.modulate = LABEL_COLOR
	label.outline_modulate = LABEL_OUTLINE_COLOR
	label.position = Vector3(object.position.x, 0.7 * object.scale, object.position.y)


func _process(_delta: float) -> void:
	var camera := get_viewport().get_camera_3d()
	if camera == null:
		return
	for label: Label3D in labels.values():
		label.visible = (
			camera.global_position.distance_squared_to(label.global_position)
			<= LABEL_VISIBLE_DISTANCE_SQ
		)
