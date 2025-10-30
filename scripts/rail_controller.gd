extends Camera3D

# === Exported variables ===
@export var follow_target: Node3D
@export var offset_back_explore: float = 2.5
@export var offset_back_combat: float = 1.2
@export var offset_up: float = 1.3
@export var mouse_sensitivity: float = 0.1
@export var look_limit_v: float = 60.0
@export var zoom_speed: float = 3.0

# === Internal variables ===
var yaw := 0.0
var pitch := 0.0
var mouse_locked := true
var in_combat := false
var current_offset_back := 2.5

# === Crosshair UI reference ===
var crosshair: Control

func _ready():
	if Engine.is_editor_hint():
		return

	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	current_offset_back = offset_back_explore

	# Create a simple crosshair if none exists
	_create_crosshair()

func _unhandled_input(event):
	if event is InputEventMouseMotion and mouse_locked:
		yaw -= event.relative.x * mouse_sensitivity
		pitch -= event.relative.y * mouse_sensitivity
		pitch = clamp(pitch, -look_limit_v, look_limit_v)

	elif event is InputEventKey and event.pressed and event.keycode == KEY_ESCAPE:
		mouse_locked = not mouse_locked
		Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED if mouse_locked else Input.MOUSE_MODE_VISIBLE)

# === Smooth follow and rotation ===
func _process(delta: float) -> void:
	if not follow_target:
		return

	# Smooth offset transition (zoom effect)
	var target_offset = offset_back_combat if in_combat else offset_back_explore
	current_offset_back = lerp(current_offset_back, target_offset, delta * zoom_speed)

	# Follow player's position
	var target_pos = follow_target.global_position
	var camera_offset = Vector3(0, offset_up, -abs(current_offset_back))
	var rotated_offset = camera_offset.rotated(Vector3.UP, deg_to_rad(yaw))

	global_position = target_pos + rotated_offset
	rotation_degrees = Vector3(pitch, yaw, 0)

	# Look at the player (slightly above)
	look_at(target_pos + Vector3(0, offset_up * 0.5, 0))

# === Combat mode toggle ===
func set_combat_mode(active: bool):
	in_combat = active
	if crosshair:
		crosshair.visible = active

# === Create crosshair overlay ===
func _create_crosshair():
	if get_tree().root.get_node_or_null("CrosshairOverlay"):
		crosshair = get_tree().root.get_node("CrosshairOverlay")
		return

	var overlay = Control.new()
	overlay.name = "CrosshairOverlay"
	overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
	overlay.visible = false

	var label = Label.new()
	label.text = "+"
	label.add_theme_color_override("font_color", Color(0.0, 1.0, 1.0))
	label.add_theme_font_size_override("font_size", 36)
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.anchor_left = 0.5
	label.anchor_top = 0.5
	label.anchor_right = 0.5
	label.anchor_bottom = 0.5
	label.offset_left = -10
	label.offset_top = -10
	label.offset_right = 10
	label.offset_bottom = 10

	overlay.add_child(label)
	get_tree().root.add_child(overlay)
	crosshair = overlay
