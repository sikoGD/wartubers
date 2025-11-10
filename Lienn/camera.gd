extends Node3D

@export var car: PathFollow3D

@onready var cam: Camera3D = $Cam

func _process(delta: float) -> void:
	global_position = car.global_position

	
