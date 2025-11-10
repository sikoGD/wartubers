extends Node3D

@export var duration = 120
@export var sideSpeed = 30
@export var sideLimit = 13
@export var pictureAimLimits : Vector2
@export var shoorterAimLimits : Vector2

@onready var path_follow_3d: PathFollow3D = $Path3D/PathFollow3D
@onready var camera: Node3D = $camera
@onready var picture_aim: Control = $GUI/pictureAim
@onready var shooter_aim: Control = $GUI/shooterAim

func _ready() -> void:
	camera.car = path_follow_3d

func _process(delta: float) -> void:
	if Input.is_action_pressed("carLeft"):
		path_follow_3d.h_offset -= sideSpeed * delta
		if path_follow_3d.h_offset <= -sideLimit:
			path_follow_3d.h_offset = -sideLimit
	if Input.is_action_pressed("carRight"):
		path_follow_3d.h_offset += sideSpeed * delta
		if path_follow_3d.h_offset >= sideLimit:
			path_follow_3d.h_offset = sideLimit
	path_follow_3d.progress_ratio += delta / duration
	
func _unhandled_input(event: InputEvent) -> void:
	if Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT):
		picture_aim.visible = true
		var mousePos: Vector2 = get_viewport().get_mouse_position()
		mousePos.x = clamp(mousePos.x, pictureAimLimits.x, get_viewport().size.x - pictureAimLimits.x)
		mousePos.y = clamp(mousePos.y, pictureAimLimits.y, get_viewport().size.y - pictureAimLimits.y)
		Input.warp_mouse(mousePos)
		picture_aim.position = get_viewport().get_mouse_position()
		
	else:
		picture_aim.visible = false
	
	if Input.is_mouse_button_pressed(MOUSE_BUTTON_RIGHT):
		shooter_aim.visible = true
		var mousePos: Vector2 = get_viewport().get_mouse_position()
		mousePos.x = clamp(mousePos.x, 0, get_viewport().size.x)
		mousePos.y = clamp(mousePos.y, 0, get_viewport().size.y)
		Input.warp_mouse(mousePos)
		shooter_aim.position = get_viewport().get_mouse_position()
	else:
		shooter_aim.visible = false
	
