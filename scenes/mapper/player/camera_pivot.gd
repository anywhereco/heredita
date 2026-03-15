extends Node3D

@onready var player: CharacterBody3D = $".."


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass  # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _physics_process(delta: float) -> void:
	var wanted_pos := player.position
	wanted_pos.y += .5
	position += (wanted_pos - position) * (1 - exp(-40 * delta))
