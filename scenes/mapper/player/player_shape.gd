extends CSGSphere3D

@onready var player: PlayerMovement = $".."

var last_vel := Vector2.ZERO
var vertical_target := 0.0
var last_vertical_vel := 0.0
var angle_offset := 0.0
var vertical_stretch := 1.0


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass  # Replace with function body.


func ghost(enable: bool) -> void:
	var tween := create_tween()
	if enable:
		material_override.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	else:
		material_override.transparency = BaseMaterial3D.TRANSPARENCY_DISABLED
	tween.tween_property(material_override, "albedo_color:a", 0.2 if enable else 1.0, 0.5)
	tween.parallel().tween_property(
		material_override.next_pass, "albedo_color:a", 0.2 if enable else 1.0, 0.5
	)


func _process(delta: float) -> void:
	var vel := Vector2(player.velocity.x, player.velocity.z)
	if abs(vel.angle() - last_vel.angle()) > PI:
		if signf((vel - last_vel).angle()) == 1:
			angle_offset -= TAU
		else:
			angle_offset += TAU

	var angle := vel.angle() + angle_offset

	if vel.length_squared() > 0.05:
		rotation.y += (((angle * -1) + deg_to_rad(-90)) - rotation.y) * (1 - exp(-20 * delta))
		last_vel = vel
	var vertical_stretch_target := 1.0 + (absf(player.velocity.y - vertical_target) * .04)
	vertical_stretch += (vertical_stretch_target - vertical_stretch) * (1 - exp(-10 * delta))
	var vertical_stretch_lesser := 1 + ((vertical_stretch - 1) * 0.5)
	scale.z = (1 + (sqrt(vel.length()) * 0.03)) / vertical_stretch_lesser
	scale.x = 1 / vertical_stretch_lesser
	scale.y = vertical_stretch
	# TODO: we probably need an actual jump start/land animation, but this handles air fluidly
	vertical_target = (vertical_target - player.velocity.y) * .06
	#if player.velocity.y - last_vertical_vel > 3:
	#print("landed", player.velocity.y - last_vertical_vel)
	#last_vertical_vel = player.velocity.y
