extends Node3D

@onready var player: CharacterBody3D = $".."


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass  # Replace with function body.

func recenter() -> void: # Force the pivot to go directly to the player's center
	var wanted_pos := player.position
	wanted_pos.y += .5
	position = wanted_pos

func move_with(old_pos: Vector3, new_pos: Vector3) -> void: # Used to avoid camera judder when teleporting
	position += (new_pos - old_pos)

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _physics_process(delta: float) -> void:
	var wanted_pos := player.position
	wanted_pos.y += .5
	position += (wanted_pos - position) * (1 - exp(-40 * delta))
