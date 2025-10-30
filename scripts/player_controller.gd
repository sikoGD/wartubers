extends Node3D

@export var fire_rate: float = 0.25
@export var max_range: float = 50.0

var can_shoot: bool = true
var in_combat: bool = false
var camera: Camera3D

@onready var sprite: Sprite3D = $Sprite
@onready var muzzle_flash_scene: PackedScene = preload("res://scenes/effects/muzzle_flash.tscn")
@onready var aim_controller: Node = $AimController

func _ready() -> void:
	# Try to find camera automatically
	camera = get_viewport().get_camera_3d()
	if camera == null:
		var cam = Camera3D.new()
		add_child(cam)
		cam.position = Vector3(0, 2, -6)
		cam.current = true
		camera = cam
	print("🎯 Player ready.")

func start_combat() -> void:
	in_combat = true
	print("🔫 Combat mode: active")

func end_combat() -> void:
	in_combat = false
	print("✅ Combat mode: ended")

func _process(delta: float) -> void:
	if not in_combat:
		return

	if not camera:
		return

	# Raycast from mouse position
	var mouse_pos = get_viewport().get_mouse_position()
	var from = camera.project_ray_origin(mouse_pos)
	var to = from + camera.project_ray_normal(mouse_pos) * max_range
	var space_state = get_world_3d().direct_space_state
	var result = space_state.intersect_ray(PhysicsRayQueryParameters3D.create(from, to))

	if result:
		var target_pos = result.position
		look_at(target_pos, Vector3.UP)

		# 🟢 Update crosshair to follow aim point
		_update_crosshair(target_pos)

		# Fire
		if Input.is_action_pressed("shoot") and can_shoot:
			_shoot(from, to, result)
	else:
		look_at(to, Vector3.UP)
		_update_crosshair(to)

func _shoot(from: Vector3, to: Vector3, result: Dictionary) -> void:
	can_shoot = false
	_spawn_muzzle_flash()
	_play_shoot_effect()

	if result.has("collider") and result.collider.has_method("take_damage"):
		result.collider.take_damage()

	await get_tree().create_timer(fire_rate).timeout
	can_shoot = true

func _spawn_muzzle_flash() -> void:
	if not muzzle_flash_scene:
		return
	var flash = muzzle_flash_scene.instantiate()
	add_child(flash)
	flash.global_position = global_position + global_transform.basis.z * -0.5
	await get_tree().create_timer(0.1).timeout
	flash.queue_free()

func _play_shoot_effect() -> void:
	print("🔫 Pew!")

# 🧩 Crosshair follow system
func _update_crosshair(world_point: Vector3) -> void:
	if not camera:
		return

	# Try to find the UI layer in the main scene
	var ui_root = get_tree().get_root().get_node_or_null("Main/UI")
	if not ui_root or not ui_root.has_node("Crosshair"):
		return

	var crosshair = ui_root.get_node("Crosshair")
	var screen_pos = camera.unproject_position(world_point)

	# Adjust position to center crosshair on the point
	crosshair.position = screen_pos - crosshair.size * 0.5
