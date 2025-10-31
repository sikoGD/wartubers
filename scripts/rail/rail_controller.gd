extends Camera3D

# === Exported variables ===
@export var follow_target: Node3D
@export var offset_back_explore: float = 2.5
@export var offset_back_combat: float = 1.2
@export var offset_up: float = 1.3
@export var mouse_sensitivity: float = 0.1
@export var look_limit_v: float = 60.0
@export var zoom_speed: float = 3.0
@export var crosshair_fade_speed: float = 6.0

# === Internal state ===
var yaw := 0.0
var pitch := 0.0
var mouse_locked := true
var in_combat := false
var current_offset_back := 2.5

# === Crosshair reference ===
var crosshair: Control
var crosshair_label: Label
var crosshair_alpha: float = 0.0

func _ready():
	if Engine.is_editor_hint():
		return

	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	current_offset_back = offset_back_explore
	_create_crosshair()

	# Connect to area enter/exit signals automatically if possible
	if follow_target:
		for child in follow_target.get_children():
			if child is Area3D:
				child.body_entered.connect(_on_body_entered)
				child.body_exited.connect(_on_body_exited)
				current_offset_back = offset_back_explore
				yaw = follow_target.rotation_degrees.y
				pitch = 0


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

	# Smooth zoom transition
	var target_offset = offset_back_combat if in_combat else offset_back_explore
	current_offset_back = lerp(current_offset_back, target_offset, delta * zoom_speed)

	# Desired offset (behind player)
	var target_pos = follow_target.global_position
	var camera_offset = Vector3(0, offset_up, -abs(current_offset_back))
	var rotated_offset = camera_offset.rotated(Vector3.UP, deg_to_rad(yaw))

	# Update camera position
	global_position = target_pos + rotated_offset

	# Apply rotation directly from yaw/pitch (manual look)
	rotation_degrees = Vector3(pitch, yaw, 0)

# === Manual control (if needed) ===
func set_combat_mode(active: bool):
	in_combat = active
	if crosshair:
		crosshair.visible = active
	yaw = yaw # keeps current direction stable
	pitch = clamp(pitch, -look_limit_v, look_limit_v)
	
# === Trigger zones ===
func _on_body_entered(body):
	if body.is_in_group("EnemyZone"):
		set_combat_mode(true)

func _on_body_exited(body):
	if body.is_in_group("EnemyZone"):
		set_combat_mode(false)
		

# === Crosshair overlay creation ===
func _create_crosshair():
	if get_tree().root.get_node_or_null("CrosshairOverlay"):
		crosshair = get_tree().root.get_node("CrosshairOverlay")
		return

	var overlay = Control.new()
	overlay.name = "CrosshairOverlay"
	overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
	overlay.anchor_left = 0.0
	overlay.anchor_top = 0.0
	overlay.anchor_right = 1.0
	overlay.anchor_bottom = 1.0
	overlay.visible = false

	var label = Label.new()
	label.text = "+"
	label.add_theme_color_override("font_color", Color(0.0, 1.0, 1.0))
	label.add_theme_font_size_override("font_size", 36)
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.set_anchors_preset(Control.PRESET_CENTER)

	overlay.add_child(label)
	get_tree().root.add_child(overlay)
	crosshair = overlay

# 🔴 Flash crosshair when a hit is confirmed
func flash_crosshair_hit():
	if not crosshair:
		return
	var label := crosshair.get_child(0) as Label
	if not label:
		return

	# Flash red instantly
	label.add_theme_color_override("font_color", Color(1, 0, 0))

	# Smoothly fade back to cyan
	var tween := create_tween()
	tween.tween_property(label, "modulate", Color(0, 1, 1), 0.25).from(Color(1, 0, 0))
