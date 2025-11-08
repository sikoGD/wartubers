extends Node3D

@export var fire_rate: float = 0.25
@export var max_range: float = 50.0

var can_shoot: bool = true
var in_combat: bool = false
var camera: Camera3D
var original_position: Vector3
var original_sprite_pos: Vector3

@onready var sprite: Sprite3D = $Sprite
@onready var muzzle_flash_scene: PackedScene = preload("res://scenes/effects/muzzle_flash.tscn")

func _ready() -> void:
	# Cache original transform for reset later
	original_position = position
	original_sprite_pos = sprite.position

	print("🎯 Player ready.")

func start_combat() -> void:
	in_combat = true
	print("🔫 Combat mode: active")

	# Compute offset relative to camera LEFT direction
	var left_dir = -camera.global_transform.basis.x.normalized()
	var offset_left_player = left_dir * 0.8   # Move player left
	var offset_left_sprite = left_dir * 0.4   # Move sprite left

	# Move player
	var tween = create_tween()
	tween.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	tween.tween_property(self, "global_position",
		global_position + offset_left_player + Vector3(0, -0.15, -0.4), 0.6)

	# Move sprite
	var stween = create_tween()
	stween.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	stween.tween_property(sprite, "position",
		original_sprite_pos + offset_left_sprite + Vector3(0, -0.1, 0), 0.6)

	if camera and camera.has_method("set_combat_mode"):
		camera.set_combat_mode(true)


func end_combat() -> void:
	in_combat = false
	print("✅ Combat mode: ended")

	# Reset player & sprite to original positions
	var tween = create_tween()
	tween.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	tween.tween_property(self, "position", original_position, 0.6)

	var sprite_tween = create_tween()
	sprite_tween.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	sprite_tween.tween_property(sprite, "position", original_sprite_pos, 0.6)

	if camera and camera.has_method("set_combat_mode"):
		camera.set_combat_mode(false)

func _process(delta: float) -> void:
	if not in_combat or not camera:
		return

	var mouse_pos = get_viewport().get_mouse_position()
	var from = camera.project_ray_origin(mouse_pos)
	var to = from + camera.project_ray_normal(mouse_pos) * max_range

# create params that include areas AND bodies
	var q = PhysicsRayQueryParameters3D.create(from, to)
	q.collide_with_areas = true
	q.collide_with_bodies = true
# optionally set a collision mask: q.collision_mask = some_mask_value

	var result = get_world_3d().direct_space_state.intersect_ray(q)

	var target_pos: Vector3
	if result:
		target_pos = result.position
	else:
		target_pos = to

# face aim target
	var dir = (target_pos - global_position).normalized()
	var yaw_only = atan2(dir.x, dir.z)
	rotation_degrees.y = rad_to_deg(yaw_only)

# shooting
	if Input.is_action_pressed("shoot") and can_shoot:
		_shoot(from, to, result if result else {})

func _shoot(from: Vector3, to: Vector3, result: Dictionary) -> void:
	can_shoot = false
	_spawn_muzzle_flash()
	_play_shoot_effect()

	# debug: print what the ray hit
	if result and result.has("collider"):
		var collider = result.collider
		print_debug("Ray hit:", collider, " type:", typeof(collider))
		# climb the parent chain until we find a node that has take_damage()
		var target = collider
		# If collider is a PhysicsServer shape object rather than a Node, try .get_parent() safely.
		while target and not target.has_method("take_damage"):
			if target is Node and target.get_parent():
				target = target.get_parent()
			else:
				# can't find parent with method
				target = null
				break

		if target and target.has_method("take_damage"):
			# call with amount 1 (or any)
			target.take_damage(1)
			# flash hit effect on camera if available
			if camera and camera.has_method("flash_crosshair_hit"):
				camera.flash_crosshair_hit()
		else:
			print_debug("No take_damage() on collider or parents; collider:", collider)
	else:
		# no hit
		if camera and camera.has_method("flash_crosshair"):
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
