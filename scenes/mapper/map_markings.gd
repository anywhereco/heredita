class_name MapMarkings
extends Node3D

@onready var cities_mesh: MultiMeshInstance3D = $Cities
@onready var text_meshes: Node3D = $TextMeshes

## Dictionary[Vector2i, Array[MapObject]]
## where Vector2i is the chunk coordinates.
var map_objects: Dictionary[Vector2i, Array]

@abstract class MapObject:
	var position: Vector2
	var scale: float
	var rotation: float
	var color: Color
	var basis: Basis:
		get():
			return Basis.from_scale(Vector3.ONE * scale).rotated(Vector3(1, 0, 0), rotation)
	var transform: Transform3D:
		get():
			return Transform3D(basis, Vector3(position.x, 0.01, position.y))

	@abstract func is_in_bounds(other: Vector2) -> bool


class City:
	extends MapObject

	func is_in_bounds(other: Vector2) -> bool:
		other -= position
		return other.length_squared() <= scale ** 2


class Fort:
	extends MapObject

	func is_in_bounds(other: Vector2) -> bool:
		other -= position
		return abs(other.x) <= scale and abs(other.y) <= scale


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	cities_mesh.multimesh.instance_count = 8192
	cities_mesh.multimesh.visible_instance_count = 0

	for i: int in cities_mesh.multimesh.visible_instance_count:
		cities_mesh.multimesh.set_instance_transform(
			i,
			Transform3D(
				Basis.IDENTITY, Vector3(randf_range(-1000, 1000), 0.01, randf_range(-1000, 1000))
			)
		)
		cities_mesh.multimesh.set_instance_color(
			i, Color((randf() / 10) + .5, (randf() / 10) + .5, (randf() / 10) + .5, 1)
		)


func _process(_delta: float) -> void:
	pass
