extends Node3D

@export var speed: float = 50.0
@export var lifetime: float = 2.0

func _ready():
	await get_tree().create_timer(lifetime).timeout
	queue_free()

func _process(delta: float) -> void:
	translate(Vector3(0, 0, -speed * delta))

func _on_area_entered(area):
	if area.is_in_group("EnemyZone"):
		area.get_parent().take_damage(1)
		queue_free()
