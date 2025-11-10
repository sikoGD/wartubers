extends PathFollow3D

@export var move_speed: float = 3.0
@export var loop_path: bool = false

var path: Path3D
var curve: Curve3D

func _ready() -> void:
	# Cache the path and its curve (the parent should be a Path3D)
	path = get_parent()
	if path and path is Path3D:
		curve = path.curve
	else:
		push_warning("⚠️ PathFollow3D parent must be a Path3D with a valid Curve3D.")

func _process(delta: float) -> void:
	if curve == null:
		return

	progress += move_speed * delta

	if progress_ratio >= 1.0:
		if loop_path:
			progress = 0.0
		else:
			progress = curve.get_baked_length()  # stop at the end
