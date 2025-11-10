extends Node3D
@export var cover_normal: Vector3 = Vector3(0,0,1) # facing outwards from cover
@export var cover_strength: float = 0.5 # damage reduction (0..1)
# @export var name: String = "Cover"

func can_use_by(actor_global_pos: Vector3) -> bool:
	# simple range check
	return global_transform.origin.distance_to(actor_global_pos) < 3.5
