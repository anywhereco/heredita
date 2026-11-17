class_name BrushShapes
extends RefCounted

const SIZE_MAX := 25

static var _circles: Dictionary[int, PackedVector2Array] = {}


static func circle(size: int) -> PackedVector2Array:
	if not _circles.has(size):
		var shape := PackedVector2Array()
		for y: int in range(-size + 1, size):
			for x: int in range(-size + 1, size):
				if x * x + y * y < (size - 1) * (size - 1) + size:
					shape.append(Vector2(x, y))
		_circles[size] = shape
	return _circles[size]
