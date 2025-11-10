extends Node3D

@export var max_health: int = 5
@export var move_range: float = 3.0
@export var move_speed: float = 1.5

var health: int
var active: bool = false
var base_position: Vector3
var target_offset: Vector3 = Vector3.ZERO
var move_timer: float = 0.0
var move_interval: float = 2.0

@onready var body: MeshInstance3D = $Body

func _ready() -> void:
	health = max_health
	base_position = global_position
	set_process(false)

func start_combat() -> void:
	active = true
	set_process(true)
	print("🛸 Enemy combat activated.")

func _process(delta: float) -> void:
	if not active:
		return

	# Smooth random hovering / movement
	move_timer += delta
	if move_timer >= move_interval:
		move_timer = 0.0
		_pick_new_target_offset()

	global_position = global_position.lerp(base_position + target_offset, delta * move_speed)

func _pick_new_target_offset() -> void:
	target_offset = Vector3(
		randf_range(-move_range, move_range),
		randf_range(-move_range, move_range) * 0.5,
		randf_range(-move_range, move_range)
	)

func take_damage(amount: int = 1) -> void:
	if not active:
		return
	health -= amount
	print("💥 Enemy hit! HP:", health)
	if health <= 0:
		_die()

func _die() -> void:
	print("☠️ Enemy defeated!")
	active = false
	queue_free()
