extends Camera3D

@export var follow_target: Node3D
@export var offset_back: float = 2.5
@export var offset_up: float = 1.2
@export var mouse_sensitivity: float = 0.1
@export var look_limit_v: float = 60.0 # degrees

var yaw := 0.0
var pitch := 0.0
var mouse_locked := true

func _ready():
	if Engine.is_editor_hint():
		return
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)

func _unhandled_input(event):
	if event is InputEventMouseMotion and mouse_locked:
		yaw -= event.relative.x * mouse_sensitivity
		pitch -= event.relative.y * mouse_sensitivity
		pitch = clamp(pitch, -look_limit_v, look_limit_v)
	elif event is InputEventKey and event.pressed and event.keycode == KEY_ESCAPE:
		mouse_locked = not mouse_locked
		Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED if mouse_locked else Input.MOUSE_MODE_VISIBLE)

func _process(delta: float) -> void:
	if not follow_target:
		return

	# Compute base position relative to player
	var base_transform = follow_target.global_transform
	var offset = -base_transform.basis.z * offset_back + Vector3.UP * offset_up
	global_position = base_transform.origin + offset

	# Compute rotation with yaw/pitch
	var basis = Basis()
	basis = basis.rotated(Vector3.UP, deg_to_rad(yaw))
	basis = basis.rotated(Vector3.RIGHT, deg_to_rad(pitch))

	var look_dir = -basis.z
	look_at(global_position + look_dir, Vector3.UP)
