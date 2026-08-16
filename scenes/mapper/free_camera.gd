class_name FreeCamera
extends Node3D

@export var move_speed := 8.0
@export var camera_smoothing := 2
@export var movement_smoothing := 2
@export var camera_speed := 0.012

var active := false

var _position_current := Vector3.ZERO
var _position_target := Vector3.ZERO
var _rotation_current := Vector3.ZERO
var _rotation_target := Vector3.ZERO

@onready var player_camera: Camera3D = $"../LocalPlayer/CameraPivot/CameraArm/PlayerCamera"
@onready var speed_label: Label = $"../FreeCameraHUD/SpeedLabel"


func _ready() -> void:
	set_process(false)


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("enable_cinematic_freecam"):
		set_active(not active)
		return

	if event.is_action_pressed("hide_speed_stats"):
		speed_label.visible = not speed_label.visible
		return

	if not active:
		return

	if event is InputEventMouseMotion:
		_rotation_target.y -= event.relative.x * camera_speed
		_rotation_target.x -= event.relative.y * camera_speed
		_rotation_target.x = clampf(_rotation_target.x, deg_to_rad(-89), deg_to_rad(89))
	elif event is InputEventKey and event.pressed:
		var alt: bool = event.alt_pressed
		match event.keycode:
			KEY_UP:
				if alt:
					movement_smoothing *= 1.15
				else:
					camera_smoothing *= 1.15
			KEY_DOWN:
				if alt:
					movement_smoothing *= 1.0 / 1.15
				else:
					camera_smoothing *= 1.0 / 1.15
			KEY_RIGHT:
				if alt:
					camera_speed *= 1.15
				else:
					move_speed *= 1.15
			KEY_LEFT:
				if alt:
					camera_speed *= 1.0 / 1.15
				else:
					move_speed *= 1.0 / 1.15
		camera_smoothing = maxf(0.05, camera_smoothing)
		movement_smoothing = maxf(0.05, movement_smoothing)
		move_speed = maxf(0.1, move_speed)
		camera_speed = maxf(0.0005, camera_speed)


func _process(delta: float) -> void:
	var dir := _get_move_direction()
	_position_target += dir * move_speed * delta

	var lerp_k := 1.0 - exp(-movement_smoothing * delta)
	_position_current += (_position_target - _position_current) * lerp_k
	lerp_k = 1.0 - exp(-camera_smoothing * delta)
	_rotation_current += (_rotation_target - _rotation_current) * lerp_k

	var basis := Basis.from_euler(_rotation_current)
	player_camera.global_transform = Transform3D(basis, _position_current)

	speed_label.text = (
		"Speed: %.2f  Cam Smooth: %.3f  Move Smooth: %.3f  Cam Speed: %.4f\nijkl to move, u/o up and down\n(hide this with alt-shift-x)"
		% [move_speed, camera_smoothing, movement_smoothing, camera_speed]
	)


func set_active(value: bool) -> void:
	active = value
	player_camera.top_level = active
	speed_label.visible = active
	set_process(active)
	if active:
		var t := player_camera.global_transform
		_position_current = t.origin
		_position_target = t.origin
		_rotation_current = t.basis.get_euler()
		_rotation_target = t.basis.get_euler()


func _get_move_direction() -> Vector3:
	var basis := player_camera.global_transform.basis
	var dir := Vector3.ZERO
	if Input.is_key_pressed(KEY_I):
		dir -= basis.z
	if Input.is_key_pressed(KEY_K):
		dir += basis.z
	if Input.is_key_pressed(KEY_J):
		dir -= basis.x
	if Input.is_key_pressed(KEY_L):
		dir += basis.x
	if Input.is_key_pressed(KEY_U):
		dir += Vector3.UP
	if Input.is_key_pressed(KEY_O):
		dir += Vector3.DOWN
	return dir.normalized()
