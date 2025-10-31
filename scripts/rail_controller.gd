extends Camera3D

# === Exported variables ===
@export var follow_target: Node3D
@export var offset_back_explore: float = 2.5
@export var offset_back_combat: float = 1.2
@export var offset_up: float = 1.3
@export var mouse_sensitivity: float = 0.015    # 🧊 Much lower for smoother control
@export var look_limit_v: float = 60.0
@export var zoom_speed: float = 3.0

# === Internal variables ===
var yaw := 0.0
var pitch := 0.0
var mouse_locked := true
var in_combat := false
var current_offset_back := 2.5

# === Crosshair ===
var crosshair: Control
var label: Label

func _ready():
	if Engine.is_editor_hint():
		return

	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	current_offset_back = offset_back_explore
	_create_crosshair()
	print("🎥 RailCamera ready (static crosshair mode)")

func _unhandled_input(event):
	if event is InputEventMouseMotion and mouse_locked:
		# ✅ Correct vertical direction (mouse up = look up)
		yaw -= event.relative.x * mouse_sensitivity
		pitch += event.relative.y * mouse_sensitivity
		pitch = clamp(pitch, -look_limit_v, look_limit_v)

	elif event is InputEventKey and event.pressed and event.keycode == KEY_ESCAPE:
		mouse_locked = not mouse_locked
		Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED if mouse_locked else Input.MOUSE_MODE_VISIBLE)

func _process(delta: float) -> void:
	if not follow_target:
		return

	# Smooth offset transition
	var target_offset = offset_back_combat if in_combat else offset_back_explore
	current_offset_back = lerp(current_offset_back, target_offset, delta * zoom_speed)

	# Apply rotation
	var rot_y = Basis(Vector3.UP, deg_to_rad(yaw))
	var rot_x = Basis(Vector3.RIGHT, deg_to_rad(pitch))
	var rot = rot_y * rot_x

	# Set camera position relative to target
	var offset = Vector3(0, offset_up, -abs(current_offset_back))
	global_position = follow_target.global_position + rot * offset

	# Always look slightly above target
	look_at(follow_target.global_position + Vector3(0, offset_up * 0.5, 0))

func set_combat_mode(active: bool):
	in_combat = active
	if crosshair:
		crosshair.visible = active

	# Smoothly shift camera position to avoid blocking the crosshair
	var target_offset = offset_back_combat if active else offset_back_explore
	var shift_x = -0.6 if active else 0.0   # ← move slightly left in combat
	var shift_y = -0.4 if active else 0.0   # ↓ move slightly down in combat

	var tween := create_tween()
	tween.tween_property(self, "current_offset_back", target_offset, 0.8).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	tween.tween_property(self, "position", position + Vector3(shift_x, shift_y, 0), 0.8).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)

# === Create static crosshair overlay ===
func _create_crosshair():
	if get_tree().root.get_node_or_null("CrosshairOverlay"):
		crosshair = get_tree().root.get_node("CrosshairOverlay")
		label = crosshair.get_child(0) if crosshair.get_child_count() > 0 else null
		return

	var overlay = Control.new()
	overlay.name = "CrosshairOverlay"
	overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
	overlay.visible = false
	overlay.anchor_left = 0
	overlay.anchor_top = 0
	overlay.anchor_right = 0
	overlay.anchor_bottom = 0
	overlay.offset_left = 0
	overlay.offset_top = 0
	overlay.offset_right = 0
	overlay.offset_bottom = 0
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

func flash_crosshair():
	if not label:
		return
	label.add_theme_color_override("font_color", Color(1.0, 0.2, 0.2))
	await get_tree().create_timer(0.1).timeout
	label.add_theme_color_override("font_color", Color(0.0, 1.0, 1.0))
