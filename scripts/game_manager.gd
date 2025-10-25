extends Node3D

@onready var path_follow: PathFollow3D = $Path/PathFollow
@onready var player: Node3D = $Path/PathFollow/Player
@onready var enemy: Node3D = $Enemy
@onready var ui: CanvasLayer = $UI
@onready var combat_ui_script = ui.get_script()

var moving: bool = true
var combat_mode: bool = false
var speed: float = 2.5
var encounter_distance: float = 22.0

func _ready():
	print("⚙️ WarTubers Prototype — Exploration Start")
	enemy.visible = true
	player.position = Vector3.ZERO
	if $Path.curve == null:
		var c = Curve3D.new()
		c.add_point(Vector3(0, 0, 0))
		c.add_point(Vector3(0, 0, 5))
		c.add_point(Vector3(2, 0, 10))
		c.add_point(Vector3(-2, 1, 15))
		c.add_point(Vector3(0, 0, 20))
		$Path.curve = c
	path_follow.progress = 0.0
	moving = true
	combat_mode = false

func _process(delta: float) -> void:
	if moving:
		path_follow.progress += speed * delta
		_check_for_encounter()
	elif combat_mode:
		# Could handle combat updates later (e.g. checking if all enemies defeated)
		pass

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

	# Optional: play combat music or sound
	# $AudioStreamPlayer.play()

	# Show encounter UI fade
	if ui and ui.has_method("show_encounter"):
		ui.call_deferred("show_encounter", true)

	await get_tree().create_timer(1.5).timeout

	if ui and ui.has_method("show_encounter"):
		ui.call_deferred("show_encounter", false)

	# Tell player & enemy to start combat
	if player.has_method("start_combat"):
		player.start_combat()
	if enemy.has_method("start_combat"):
		enemy.start_combat()
