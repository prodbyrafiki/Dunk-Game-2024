extends Node3D

@onready var camera_pivot = $Camera_Pivot

var rot_speed = 8
# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	camera_pivot.rotation_degrees.y += delta * rot_speed
