extends CharacterBody3D

@export var ap_max := 5
var ap := ap_max
var in_combat := false
var selected_cover: Node = null
signal action_taken(action_name)

func start_turn():
	ap = ap_max
	in_combat = true

func end_turn():
	in_combat = false
	emit_signal("action_taken", "end_turn")

func move_to_cover(cover: Node, cost: int = 2) -> bool:
	if ap < cost:
		return false
	if not cover.get("can_use_by")(global_transform.origin):
		return false
	# snap to cover
	global_transform.origin = cover.global_transform.origin + cover.cover_normal * 0.6
	look_at(cover.global_transform.origin + cover.cover_normal * 2.0, Vector3.UP)
	selected_cover = cover
	ap -= cost
	emit_signal("action_taken", "move")
	return true

func shoot_at(target, weapon: Node) -> bool:
	var cost = 2
	if ap < cost:
		return false
	var cover_strength := 0.0
	if target.has_meta("cover_strength"):
		cover_strength = float(target.get_meta("cover_strength"))
	var hit = weapon.compute_hit(global_transform.origin, target.global_transform.origin, cover_strength)
	if hit:
		weapon.apply_damage(target, weapon.damage)
	ap -= cost
	emit_signal("action_taken", "shoot")
	return hit
