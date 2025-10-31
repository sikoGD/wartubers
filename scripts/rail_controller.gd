extends Camera3D

# === Exported variables ===
@export var follow_target: Node3D
@export var offset_back_explore: float = 2.5
@export var offset_back_combat: float = 1.2
@export var offset_up: float = 1.3
@export var mouse_sensitivity: float = 0.05   # ⬅️ Lowered sensitivity
@export var look_limit_v: float = 60.0
@export var zoom_speed: float = 3.0

# === Internal variables ===
var yaw := 0.0
var pitch := 0.0
var mouse_locked := true
var in_combat := false
var current_offset_back := 2.5
var crosshair: Control
var label: Label

func _ready():
	if Engine.is_editor_hint():
		return

	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	current_offset_back = offset_back_explore

	_create_crosshair()
	print("🎥 RailCamera ready")

func _unhandled_input(event):
	if event is InputEventMouseMotion and mouse_locked:
		# ✅ FIX: invert vertical motion (now natural feeling)
		yaw -= event.relative.x * mouse_sensitivity
		pitch += event.relative.y * mouse_sensitivity   # was -= before
		pitch = clamp(pitch, -look_limit_v, look_limit_v)

	elif event is InputEventKey and event.pressed and event.keycode == KEY_ESCAPE:
		mouse_locked = not mouse_locked
		Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED if mouse_locked else Input.MOUSE_MODE_VISIBLE)

# === Smooth follow and rotation ===
func _process(delta: float) -> void:
	if not follow_target:
		return

	# Smooth offset transition
	var target_offset = offset_back_combat if in_combat else offset_back_explore
	current_offset_back = lerp(current_offset_back, target_offset, delta * zoom_speed)

	# Rotation math
	var rot = Basis()
	rot = Basis(Vector3.UP, deg_to_rad(yaw))
	rot = rot.rotated(rot.x, deg_to_rad(pitch))

	# Camera position behind player
	var offset = Vector3(0, offset_up, -abs(current_offset_back))
	var cam_pos = follow_target.global_position + rot * offset
	global_position = cam_pos

	# Always look at player
	look_at(follow_target.global_position + Vector3(0, offset_up * 0.5, 0))

	# ✅ Crosshair stays centered
	if crosshair:
		var screen_size = get_viewport().get_visible_rect().size
		crosshair.position = screen_size * 0.5 - crosshair.size * 0.5

# === Combat mode toggle ===
func set_combat_mode(active: bool):
	in_combat = active
	if crosshair:
		crosshair.visible = active
	current_offset_back = offset_back_combat if active else offset_back_explore

# === Crosshair overlay ===
func _create_crosshair():
	if get_tree().root.get_node_or_null("CrosshairOverlay"):
		crosshair = get_tree().root.get_node("CrosshairOverlay")
		label = crosshair.get_child(0)
		return

	var overlay = Control.new()
	overlay.name = "CrosshairOverlay"
	overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
	overlay.visible = false
	overlay.anchor_left = 0.5
	overlay.anchor_top = 0.5
	overlay.anchor_right = 0.5
	overlay.anchor_bottom = 0.5

	label = Label.new()
	label.text = "+"
	label.add_theme_color_override("font_color", Color(0.0, 1.0, 1.0))
	label.add_theme_font_size_override("font_size", 36)
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.position = Vector2(-10, -10)

	overlay.add_child(label)
	get_tree().root.add_child(overlay)
	crosshair = overlay

# === Flash crosshair when firing ===
func flash_crosshair():
	if not crosshair or not label:
		return
	label.add_theme_color_override("font_color", Color(1.0, 0.2, 0.2))
	await get_tree().create_timer(0.1).timeout
	label.add_theme_color_override("font_color", Color(0.0, 1.0, 1.0))
 
