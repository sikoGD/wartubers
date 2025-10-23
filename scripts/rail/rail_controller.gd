extends Node3D
@export var path: Path3D
@export var speed: float = 6.0

var follow: PathFollow3D
var playing := true

func _ready():
	follow = PathFollow3D.new()
	path.add_child(follow)
	follow.unit_offset = 0.0
	follow.loop = false

func _process(delta):
	if playing:
		follow.unit_offset += speed * delta / path.curve.get_baked_length()
		# clamp to 1
		if follow.unit_offset >= 1.0:
			follow.unit_offset = 1.0
			playing = false
			emit_signal("rail_finished")
		# position camera or player to follow
		global_transform.origin = follow.global_transform.origin

# call to pause when encounter starts
func pause_rail():
	playing = false

func resume_rail():
	playing = true
