class_name PlayerCamera3D
extends Camera3D

@export_range(0.0, 1.0) var mouse_sensitivity := 0.01
@export var tilt_limit := deg_to_rad(75)

var topdown_camera := ReactiveBool.new(false)
var camera_left := false
var camera_right := false
var camera_up := false
var camera_down := false

@onready var camera_arm: SpringArm3D = $".."
@onready var camera_pivot: Node3D = $"../.."
@onready var player: CharacterBody3D = $"../../.."

func _process(delta: float) -> void:
	var camera_move := Vector2.ZERO
	if camera_left:
		camera_move -= Vector2.LEFT * 250
	if camera_right:
		camera_move -= Vector2.RIGHT * 250
	if camera_up:
		camera_move -= Vector2.UP * 250
	if camera_down:
		camera_move -= Vector2.DOWN * 250
	camera_pan(camera_move * delta)


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action("camera_left"):
		camera_left = event.is_pressed()
	if event.is_action("camera_right"):
		camera_right = event.is_pressed()
	if event.is_action("camera_up"):
		camera_up = event.is_pressed()
	if event.is_action("camera_down"):
		camera_down = event.is_pressed()

	if event is InputEventMouseMotion:
		if (event.button_mask & (MOUSE_BUTTON_MASK_RIGHT | MOUSE_BUTTON_MASK_MIDDLE)) != 0:
			@warning_ignore("unsafe_call_argument")
			camera_pan(Vector2(-event.relative.x, event.relative.y))
			VirtualMouse._instance.set_action(VirtualMouse.Action.PANNING)
		else:
			VirtualMouse._instance.set_action(VirtualMouse._instance.tool_action)

	if (
		event is InputEventMouseButton
		and not event.pressed
		and event.button_index in [MOUSE_BUTTON_RIGHT, MOUSE_BUTTON_MIDDLE]
	):
		VirtualMouse._instance.set_action(VirtualMouse._instance.tool_action)

	if event.is_action_pressed("zoom_out"):
		camera_arm.spring_length = minf(50, camera_arm.spring_length * 1.1)
	elif event.is_action_pressed("zoom_in"):
		camera_arm.spring_length = maxf(2.5, camera_arm.spring_length * (1 / 1.1))
	elif event.is_action_pressed("topdown_cam"):
		topdown_camera.value = not topdown_camera.value
		if topdown_camera.value:
			camera_pivot.rotation.y = 0
			camera_pivot.rotation.x = deg_to_rad(-90)
		else:
			camera_pivot.rotation.x = deg_to_rad(-45)


func camera_pan(vec: Vector2) -> void:
	if not topdown_camera.value:
		camera_pivot.rotation.x -= vec.y * mouse_sensitivity * Settings.getv("camera_sensitivity")
		# Prevent the camera from rotating too far up or down.
		camera_pivot.rotation.x = clampf(camera_pivot.rotation.x, -tilt_limit, tilt_limit / 2)
	else:
		camera_pivot.rotation.x = deg_to_rad(-90)
	camera_pivot.rotation.y += vec.x * mouse_sensitivity * Settings.getv("camera_sensitivity")
