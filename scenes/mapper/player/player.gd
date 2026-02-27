class_name PlayerMovement
extends CharacterBody3D

var local: bool = true

var frame_data: Dictionary = {} #outgoing if local, incoming if non-local

@onready var camera_pivot: Node3D = $CameraPivot
@onready var map: Map = $/root/Mapper3D/Map

const SPEED = 5.0
const SPRINT_MULT = 5.0
const JUMP_VELOCITY = 4.5

const MAX_NAME_VIEW_DISTANCE = 15

var jump: bool = false
var jump_new: bool = false
var forwards: bool = false
var backwards: bool = false
var left: bool = false
var right: bool = false

var camera_rotation: float = 0.0
var was_on_floor_last_frame: bool = false

func _ready() -> void:
	if not local:
		$CameraPivot.queue_free()
		$Name.show()

func setup_velocity(direction: Vector3, delta: float) -> void:
	var target_vel := direction * SPEED * (SPRINT_MULT if Input.is_action_pressed("sprint") else 1.0)
	var clock: float
	if direction:
		clock = -60 if is_on_floor() else -40
		direction *= SPEED
	else:
		clock = -25 if is_on_floor() else -15
		
	var weight: float = 1.0 - exp(clock * delta)
	
	var horizontal_vel := Vector2(velocity.x, velocity.z)
	var horizontal_target := Vector2(target_vel.x, target_vel.z)
	var dist_sq := horizontal_vel.distance_squared_to(horizontal_target)
	
	# If we are very close to the target, snap to it to avoid infinite tiny calculations
	if dist_sq < 0.002:
		velocity.x = target_vel.x
		velocity.z = target_vel.z
	else:
		velocity.x = lerp(velocity.x, target_vel.x, weight)
		velocity.z = lerp(velocity.z, target_vel.z, weight)

func _unhandled_input(event: InputEvent) -> void:
	if local:
		if event.is_action_pressed("jump"):
			jump_new = true
		elif event.is_action_released("jump"):
			jump = false
		if event.is_action("move_forwards"):
			forwards = event.is_pressed()
		if event.is_action("move_backwards"):
			backwards = event.is_pressed()
		if event.is_action("move_left"):
			left = event.is_pressed()
		if event.is_action("move_right"):
			right = event.is_pressed()

func _physics_process(delta: float) -> void:
	if not local and frame_data:
		@warning_ignore("unsafe_call_argument")
		position = ISUtil.to_vec3(frame_data["position"])
		@warning_ignore("unsafe_call_argument")
		rotation = ISUtil.to_vec3(frame_data["rotation"])
		@warning_ignore("unsafe_call_argument")
		velocity = ISUtil.to_vec3(frame_data["velocity"])
		camera_rotation = frame_data["camera_rotation"]
		jump = frame_data["jump"]
		frame_data = {}
	else:
		if jump:
			jump_new = false
		if jump_new:
			jump = true
		# Add the gravity.
		if not is_on_floor():
			velocity += get_gravity() * delta

		# Handle jump.
		if (jump_new and is_on_floor()) or \
		(jump and is_on_floor() and not was_on_floor_last_frame):
			velocity.y = JUMP_VELOCITY

		# Get the input direction and handle the movement/deceleration.
		var input_dir := Vector2(right,backwards) - Vector2(left,forwards)
		var direction := (transform.basis * Vector3(input_dir.x, 0, input_dir.y))
		if local:
			camera_rotation = camera_pivot.rotation.y
		direction = direction.rotated(Vector3.UP, camera_rotation).normalized()
		
		setup_velocity(direction, delta)
		
		var pos2: Vector2 = Vector2(position.x, position.z)
		
		if not map.map_world_bounds.has_point(pos2):
			if not map.map_world_bounds.has_point(Vector2(position.x, 0)):
				position.x = -position.x * 0.99
				if local:
					camera_pivot.position = position
			#if not map.map_world_bounds.has_point(Vector2(0, position.z)):
			#	position.z = -position.z
			
		move_and_slide()
		if local:
			frame_data = {"position":[position.x,position.y,position.z],
						  "rotation":[rotation.x,rotation.y,rotation.z],
						  "velocity":[velocity.x,velocity.y,velocity.z],
						  "camera_rotation":camera_rotation,
						  "jump": jump}
			if State.client:
				State.client.send("avatar_update",frame_data)

func _process(_delta: float) -> void:
	if not local:
		@warning_ignore("unsafe_call_argument")
		if position.distance_to($/root/Mapper3D/LocalPlayer.position) < 0.9: #slightly less than full diameter
			$PlayerShape.ghost(true)
		else:
			$PlayerShape.ghost(false)
		@warning_ignore("unsafe_call_argument")
		var name_distance: float = get_tree().root.get_camera_3d().global_position.distance_to($Name.global_position)
		$Name.pixel_size = 0.0025 * sqrt(name_distance)
		$Name.visible = name_distance < MAX_NAME_VIEW_DISTANCE
