extends Node3D

@export var fire_rate: float = 0.25
@export var max_range: float = 50.0

var can_shoot: bool = true
var in_combat: bool = false
var camera: Camera3D

@onready var sprite: Sprite3D = $Sprite
@onready var muzzle_flash_scene: PackedScene = preload("res://scenes/effects/muzzle_flash.tscn")

func _ready() -> void:
	# Try to find the RailCamera automatically
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

	if camera and camera.has_method("set_combat_mode"):
		camera.set_combat_mode(true)

func end_combat() -> void:
	in_combat = false
	print("✅ Combat mode: ended")

	if camera and camera.has_method("set_combat_mode"):
		camera.set_combat_mode(false)

func _process(delta: float) -> void:
	if not in_combat or not camera:
		return

	# --- Raycast from the mouse cursor ---
	var mouse_pos = get_viewport().get_mouse_position()
	var from = camera.project_ray_origin(mouse_pos)
	var to = from + camera.project_ray_normal(mouse_pos) * max_range
	var space_state = get_world_3d().direct_space_state
	var result = space_state.intersect_ray(PhysicsRayQueryParameters3D.create(from, to))

	var target_pos: Vector3
	if result:
		target_pos = result.position
	else:
		target_pos = to

	# --- Face the aim point smoothly ---
	look_at(target_pos, Vector3.UP)

	# --- Keep sprite rotation aligned with camera yaw ---
	var cam_rot_y = camera.rotation_degrees.y
	rotation_degrees.y = cam_rot_y

	# --- Shooting logic ---
	if Input.is_action_pressed("shoot") and can_shoot:
		_shoot(from, to, result if result else {})

func _shoot(from: Vector3, to: Vector3, result: Dictionary) -> void:
	can_shoot = false
	_spawn_muzzle_flash()
	_play_shoot_effect()

	# 🔴 Flash crosshair when firing or hitting
	if camera:
		if result.has("collider") and result.collider.has_method("take_damage"):
			result.collider.take_damage()
			if camera.has_method("flash_crosshair_hit"):
				camera.flash_crosshair_hit()
		elif camera.has_method("flash_crosshair"):
			camera.flash_crosshair()

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
