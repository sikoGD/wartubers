extends Node3D

@export var camera_node: Camera3D
@export var bullet_scene: PackedScene
@export var fire_rate: float = 0.2
@export var aim_sensitivity: float = 0.15

var can_shoot := true
var pitch := 0.0
var yaw := 0.0

func _unhandled_input(event):
	if event is InputEventMouseMotion:
		yaw -= event.relative.x * aim_sensitivity
		pitch -= event.relative.y * aim_sensitivity
		pitch = clamp(pitch, -45, 45)
		rotation_degrees = Vector3(pitch, yaw, 0)

	if event.is_action_pressed("shoot") and can_shoot:
		_shoot()

func _shoot():
	if not camera_node:
		return

	can_shoot = false
	await get_tree().create_timer(fire_rate).timeout
	can_shoot = true

	# Spawn a simple bullet or ray
	var bullet = bullet_scene.instantiate()
	get_tree().root.add_child(bullet)
	bullet.global_position = camera_node.global_position
	bullet.look_at(camera_node.global_position + -camera_node.global_transform.basis.z)
