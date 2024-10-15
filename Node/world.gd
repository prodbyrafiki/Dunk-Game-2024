extends Node3D

@onready var player = $Enviroment/player

func _physics_process(delta):
	get_tree().call_group("Enemies", "update_target_location", player.global_transform.origin)
