extends Node3D

@export var duration: float = 0.3
@export var flash_scale: float = 1.5

var time_passed: float = 0.0
var initial_scale: Vector3

func _ready() -> void:
	initial_scale = scale
	set_process(true)
	# Optional: if there’s a light or mesh child, you can tweak it here
	if has_node("Light"):
		$Light.visible = true

func _process(delta: float) -> void:
	time_passed += delta
	# Simple pulse effect
	var pulse = 1.0 + sin(time_passed * 20.0) * 0.2
	scale = initial_scale * (1.0 + (flash_scale - 1.0) * pulse)

	if time_passed >= duration:
		queue_free()
