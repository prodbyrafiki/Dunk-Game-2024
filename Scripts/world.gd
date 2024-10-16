extends Node3D
@onready var hit_rect = $UI/HitRect
@onready var spawns = $Spawns
@onready var navigation_region = $Enviroment/NavigationRegion3D

var enemy = preload("res://Node/enemybody.tscn")
var instance

func _ready():
	randomize()


func _on_player_player_hit():
	hit_rect.visible = true
	await get_tree().create_timer(0.2).timeout
	hit_rect.visible = false
	
	
func _get_random_child(parent_node):
	var random_id = randi() % parent_node.get_child_count()
	return parent_node.get_child(random_id)


func _on_enemy_spawn_timer_timeout():
	if spawns.get_child_count() == 0:
		print("No spawn points found!")
		return

	var spawn_point = _get_random_child(spawns).global_position
	print("Spawning at:", spawn_point)  # Check spawn point position
	
	instance = enemy.instantiate()  
	
	navigation_region.add_child(instance)

 # Create a new Transform3D and update only the position (origin)
	var new_transform = instance.global_transform
	new_transform.origin = spawn_point
	instance.global_transform = new_transform  # Assign the updated transform
