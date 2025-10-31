extends Node3D

@onready var path_follow: PathFollow3D = $Path/PathFollow
@onready var player: Node3D = $Path/PathFollow/Player
@onready var enemy: Node3D = $Enemy
@onready var rail_camera: Camera3D = $Path/PathFollow/Player/RailCamera
@onready var ui: CanvasLayer = $UI

var moving: bool = true
var combat_mode: bool = false
var speed: float = 2.5
var encounter_distance: float = 22.0

func _ready():
	print("⚙️ WarTubers Prototype — Exploration Start")

	# Ensure path has points
	if $Path.curve == null:
		var c = Curve3D.new()
		c.add_point(Vector3(0, 0, 0))
		c.add_point(Vector3(0, 0, 5))
		c.add_point(Vector3(2, 0, 10))
		c.add_point(Vector3(-2, 1, 15))
		c.add_point(Vector3(0, 0, 20))
		$Path.curve = c

	path_follow.progress = 0.0
	player.position = Vector3.ZERO
	moving = true
	combat_mode = false

	# Assign AimController camera dynamically
	var aim_controller = player.get_node_or_null("AimController")
	if aim_controller:
		aim_controller.camera_node = rail_camera
		print("🎯 RailCamera assigned to AimController")
	else:
		push_warning("⚠️ AimController not found under Player!")

	# Hide crosshair + set mode label
	if ui.has_node("Crosshair"):
		ui.get_node("Crosshair").visible = false
	if ui.has_node("CombatLabel"):
		ui.get_node("CombatLabel").text = "EXPLORATION MODE"

func _process(delta: float) -> void:
	if moving:
		path_follow.progress += speed * delta
		_check_for_encounter()

func _check_for_encounter() -> void:
	var player_pos = path_follow.global_position
	var enemy_pos = enemy.global_position
	var dist = player_pos.distance_to(enemy_pos)

	if dist < 6.0 and not combat_mode:
		_start_combat()

func _start_combat() -> void:
	if combat_mode:
		return

	print("⚠️ Combat Encounter Triggered!")

	# Stop path movement first to stabilize
	moving = false
	await get_tree().process_frame  # wait one frame for PathFollow to settle

	combat_mode = true
	print("🎯 Combat Mode Engaged")

	# Lock player position before zoom
	if player:
		player.global_position = $Path/PathFollow.global_position

	# Smoothly zoom camera and enter combat
	if rail_camera and rail_camera.has_method("set_combat_mode"):
		rail_camera.set_combat_mode(true)

	# UI crosshair + label
	if ui:
		if ui.has_node("Crosshair"):
			ui.get_node("Crosshair").visible = true
		if ui.has_node("CombatLabel"):
			ui.get_node("CombatLabel").text = "COMBAT MODE"

	# Small cinematic delay for stability
	await get_tree().create_timer(0.5).timeout

	# Now safely start combat logic
	if player.has_method("start_combat"):
		player.start_combat()
	if enemy.has_method("start_combat"):
		enemy.start_combat()

	print("🔫 Combat Started Cleanly")

func end_combat() -> void:
	print("🏁 Combat ended — returning to exploration mode.")
	combat_mode = false
	moving = true

	# Reset UI
	if ui:
		if ui.has_node("Crosshair"):
			ui.get_node("Crosshair").visible = false
		if ui.has_node("CombatLabel"):
			ui.get_node("CombatLabel").text = "EXPLORATION MODE"

	# Reset camera zoom
	if rail_camera and rail_camera.has_method("set_combat_mode"):
		rail_camera.set_combat_mode(false)

	# Reset player combat flag safely
	if player and "in_combat" in player:
		player.in_combat = false
