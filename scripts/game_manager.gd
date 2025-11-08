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

var original_camera_pos: Vector3
var original_camera_rot: Vector3
var original_fov: float

func _ready():
	print("⚙️ WarTubers Prototype — Exploration Start")

	var player = $Path/PathFollow/Player
	var camera = player.get_node("RailCamera")

	player.camera = camera

	path_follow.progress = 0.0
	player.position = Vector3.ZERO
	moving = true
	combat_mode = false

	# --- Save original camera data ---
	original_camera_pos = rail_camera.position
	original_camera_rot = rail_camera.rotation
	original_fov = rail_camera.fov

	# --- Assign camera to AimController ---
	var aim_controller = player.get_node_or_null("AimController")
	if aim_controller:
		aim_controller.camera_node = rail_camera
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
	var dist = path_follow.global_position.distance_to(enemy.global_position)
	if dist < 6.0 and not combat_mode:
		_start_combat()

func _start_combat() -> void:
	moving = false
	combat_mode = true
	print("⚠️ Combat Encounter Started!")

	# ✅ SMOOTH + STABLE CAMERA TRANSITION (NO ROTATION, NO FOV)
	if rail_camera:
		var tween = create_tween()
		tween.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)

		# small combat offset (this prevents shaking)
		var combat_position = original_camera_pos + Vector3(0.0, 0.15, -0.8)

		tween.tween_property(
			rail_camera,
			"position",
			combat_position,
			0.6
		)

	# ✅ UI
	if ui:
		if ui.has_node("Crosshair"):
			ui.get_node("Crosshair").visible = true
		if ui.has_node("CombatLabel"):
			ui.get_node("CombatLabel").text = "COMBAT MODE"

	# Optional encounter fade
	if ui and ui.has_method("show_encounter"):
		ui.call_deferred("show_encounter", true)
	await get_tree().create_timer(1.2).timeout
	if ui and ui.has_method("show_encounter"):
		ui.call_deferred("show_encounter", false)

	# ✅ Start combat scripts
	if player.has_method("start_combat"):
		player.start_combat()
	if enemy.has_method("start_combat"):
		enemy.start_combat()

func _end_combat() -> void:
	combat_mode = false
	moving = true

	# Return camera smoothly
	if rail_camera:
		var tween = create_tween()
		tween.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
		tween.tween_property(rail_camera, "position", original_camera_pos, 0.6)

	# UI reset
	if ui.has_node("Crosshair"):
		ui.get_node("Crosshair").visible = false
	if ui.has_node("CombatLabel"):
		ui.get_node("CombatLabel").text = "EXPLORATION MODE"

	# Player reset
	if player.has_method("end_combat"):
		player.end_combat()
