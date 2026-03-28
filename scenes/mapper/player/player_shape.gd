extends CSGSphere3D

const TURN_SPEED := 12.0 


@onready var player: PlayerMovement = $".."

var last_vel := Vector2.ZERO
var vertical_target := 0.0
var last_vertical_vel := 0.0
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
	
	var vel := Vector2(player.velocity.x, -player.velocity.z)
	var angle := vel.angle()
	
	if vel.length_squared() > 2: # if we aren't moving we don't want to rotate
		rotation.y -= deg_to_rad(-90) # we need to do this so the face location matches up
		
		rotation.y = fposmod(
			lerp_angle(rotation.y, angle, TURN_SPEED * delta), 
			TAU
		)
		
		rotation.y += deg_to_rad(-90)
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
