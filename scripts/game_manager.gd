extends Node3D

@onready var path_follow: PathFollow3D = $Path/PathFollow
@onready var player: Node3D = $Path/PathFollow/Player
@onready var enemy: Node3D = $Enemy
@onready var rail_camera: Camera3D = $Path/PathFollow/Player/RailCamera
@onready var ui: CanvasLayer = $UI
@onready var combat_ui_script = ui.get_script()

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

	# --- Assign AimController camera reference dynamically ---
	var aim_controller = player.get_node_or_null("AimController")
	if aim_controller:
		aim_controller.camera_node = rail_camera
		print("🎯 RailCamera assigned to AimController")
	else:
		push_warning("⚠️ AimController not found under Player!")

	# UI setup
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
	moving = false
	combat_mode = true
	print("⚠️ Combat Encounter Started!")

	# Zoom camera in
	if rail_camera and rail_camera.has_method("set_combat_mode"):
		rail_camera.set_combat_mode(true)

	# UI crosshair + label
	if ui:
		if ui.has_node("Crosshair"):
			ui.get_node("Crosshair").visible = true
		if ui.has_node("CombatLabel"):
			ui.get_node("CombatLabel").text = "COMBAT MODE"

	# Optional: show encounter fade
	if ui and ui.has_method("show_encounter"):
		ui.call_deferred("show_encounter", true)
	await get_tree().create_timer(1.5).timeout
	if ui and ui.has_method("show_encounter"):
		ui.call_deferred("show_encounter", false)

	# Start combat logic for player & enemy
	if player.has_method("start_combat"):
		player.start_combat()
	if enemy.has_method("start_combat"):
		enemy.start_combat()
