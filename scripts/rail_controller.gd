extends Camera3D

# === Exported ===
@export var follow_target: Node3D
@export var offset_back_explore: float = 2.5
@export var offset_back_combat: float = 2.0
@export var offset_up: float = 1.3
@export var mouse_sensitivity: float = 0.015
@export var look_limit_v: float = 60.0
@export var zoom_speed: float = 3.0

# === Internal ===
var yaw := 0.0
var pitch := 0.0
var mouse_locked := true
var in_combat := false
var current_offset_back := 2.5

# Combat shift (lateral + vertical)
var combat_shift := Vector3.ZERO
var target_shift := Vector3.ZERO

# Crosshair UI
var crosshair: Control
var label: Label


# ============================================================
# ✅ CROSSHAIR CREATION — placed BEFORE _ready() to avoid parser errors
# ============================================================
func _create_crosshair():
	# Avoid duplicates
	if get_tree().root.get_node_or_null("CrosshairOverlay"):
		crosshair = get_tree().root.get_node("CrosshairOverlay")
		label = crosshair.get_child(0) if crosshair.get_child_count() > 0 else null
		return

	var overlay := Control.new()
	overlay.name = "CrosshairOverlay"
	overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
	overlay.visible = false
	overlay.set_anchors_preset(Control.PRESET_FULL_RECT)

	label = Label.new()
	label.text = "+"
	label.add_theme_color_override("font_color", Color(0.0, 1.0, 1.0))
	label.add_theme_font_size_override("font_size", 36)
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.anchor_left = 0.5
	label.anchor_top = 0.5
	label.anchor_right = 0.5
	label.anchor_bottom = 0.5
	label.position = Vector2.ZERO

	overlay.add_child(label)
	get_tree().root.add_child(overlay)
	crosshair = overlay


# ============================================================
# ✅ READY
# ============================================================
func _ready():
	if Engine.is_editor_hint():
		return

	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)

	current_offset_back = offset_back_explore

	_create_crosshair()

	print("🎥 RailCamera ready")


# ============================================================
# ✅ INPUT
# ============================================================
func _unhandled_input(event):
	if event is InputEventMouseMotion and mouse_locked:
		yaw -= event.relative.x * mouse_sensitivity
		pitch += event.relative.y * mouse_sensitivity
		pitch = clamp(pitch, -look_limit_v, look_limit_v)

	elif event is InputEventKey and event.pressed and event.keycode == KEY_ESCAPE:
		mouse_locked = not mouse_locked
		Input.set_mouse_mode(
			Input.MOUSE_MODE_CAPTURED if mouse_locked else Input.MOUSE_MODE_VISIBLE
		)


# ============================================================
# ✅ PROCESS — main camera logic
# ============================================================
func _process(delta: float):
	if not follow_target:
		return

	# Smooth zoom transition
	var target_offset = offset_back_combat if in_combat else offset_back_explore
	current_offset_back = lerp(current_offset_back, target_offset, delta * zoom_speed)

	# Smooth combat shift transition
	combat_shift = combat_shift.lerp(target_shift, delta * 3.0)

	# Rotation (look around)
	var rot_y = Basis(Vector3.UP, deg_to_rad(yaw))
	var rot_x = Basis(Vector3.RIGHT, deg_to_rad(pitch))
	var rot = rot_y * rot_x

	# Base camera offset
	var offset = Vector3(0, offset_up, -abs(current_offset_back))

	# ✅ Camera position = follow target + camera offset + combat shift
	global_position = follow_target.global_position + rot * offset + combat_shift

	# Always look slightly above the player
	look_at(follow_target.global_position + Vector3(0, offset_up * 0.5, 0))


# ============================================================
# ✅ COMBAT MODE
# ============================================================
func set_combat_mode(active: bool):
	in_combat = active

	if crosshair:
		crosshair.visible = active

	# ✅ Smooth permanent offset (left + down)
	if active:
		target_shift = Vector3(-0.8, -0.10, 0)	# adjust here anytime
	else:
		target_shift = Vector3.ZERO
