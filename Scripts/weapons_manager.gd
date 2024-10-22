extends Node3D

signal Weapon_Changed
signal Update_Ammo
signal Update_Weapon_Stack

@onready var animation_player = $Weapons_Rig/AnimationPlayer
@onready var bullet_point = %Bullet_Point

var current_weapon = null
var weapon_stack = []
var weapon_indicator = 0
var next_weapon: String
var weapon_list = {}

@export var _weapon_resources: Array[weapons_res]
@export var start_weapons: Array[String]
@export var starting_weapon: String  # Define which weapon to start with

var instance

enum {
	NULL, 
	HITSCAN, 
	PROJECTILE,
	}

func _ready():
	initialize()  # Initialize the state machine
	print("Ready function called")

func initialize():
	weapon_list.clear()  # Clear the list to prevent duplicates
	weapon_stack.clear()  # Clear stack before filling it again
	
	# Does check for whether or not weapons are present in list 
	for weapon in _weapon_resources:
		if weapon.Weapon_Name not in weapon_list:
			print("Weapon resource found: ", weapon.Weapon_Name)
			weapon_list[weapon.Weapon_Name] = weapon
		else:
			print("Duplicate weapon resource ignored: ", weapon.Weapon_Name)

	# Fills weapons stacks and pulls from weapon list
	for weapon_name in start_weapons:
		if weapon_list.has(weapon_name):
			weapon_stack.push_back(weapon_name)
			print("Added to weapon stack: ", weapon_name)
		else:
			print("Error: Weapon not found in weapon_list: ", weapon_name)

	# Step 3: Set the current weapon based on starting_weapon
	print("--- Setting Starting Weapon ---")
	if weapon_stack.size() > 0:
		if weapon_list.has(starting_weapon):
			# Start with the specific weapon if found
			current_weapon = weapon_list[starting_weapon]
			weapon_indicator = weapon_stack.find(starting_weapon)
			print("Starting weapon set to: ", starting_weapon)
		else:
			# Switches to the first weapon in the stack if the specific one is not found
			current_weapon = weapon_list.get(weapon_stack[0], null)
			weapon_indicator = 0
			print("Error: Starting weapon '", starting_weapon, "' not found, defaulting to: ", weapon_stack[0])
	else:
		print("Error: weapon_stack is empty")

	# Step 4: Final check on current_weapon
	if current_weapon == null:
		print("Error: Current weapon is null")
	else:
		print("Current weapon set to: ", current_weapon.Weapon_Name)
		emit_signal("Update_Weapon_Stack", weapon_stack)
		enter()

func enter(): 
	if current_weapon:
		print("Entering weapon: ", current_weapon.Weapon_Name)
		print("Queued animation: ", current_weapon.Activate_Anim) 
		animation_player.queue(current_weapon.Activate_Anim)
		print("Playing activate animation for: ", current_weapon.Weapon_Name)
		emit_signal("Weapon_Changed", current_weapon.Weapon_Name)
		emit_signal("Update_Ammo",[current_weapon.Current_Ammo, current_weapon.Reserve_Ammo])

func _input(event):
	# Handle weapon switching
	if event.is_action_pressed("weapon_up"):
		weapon_indicator = min(weapon_indicator + 1, weapon_stack.size() - 1)
		print("Switching weapon up to: ", weapon_stack[weapon_indicator])
		exit(weapon_stack[weapon_indicator])

	if event.is_action_pressed("weapon_down"):
		weapon_indicator = max(weapon_indicator - 1, 0)
		print("Switching weapon down to: ", weapon_stack[weapon_indicator])
		exit(weapon_stack[weapon_indicator])
		
	if event.is_action_pressed("shoot"):
		shoot()
		
	if event.is_action_pressed("reload"):
		reload()

func exit(_next_weapon: String):
	if current_weapon and _next_weapon != current_weapon.Weapon_Name:
		if animation_player.get_current_animation() != current_weapon.Deactivate_Anim:
			print("Switching from: ", current_weapon.Weapon_Name, " to: ", _next_weapon)
			animation_player.play(current_weapon.Deactivate_Anim)
			next_weapon = _next_weapon

func change_weapon(weapon_name: String):
	if weapon_list.has(weapon_name):
		current_weapon = weapon_list[weapon_name]
		next_weapon = ""
		enter()

func _on_animation_player_animation_finished(anim_name):
	if anim_name == current_weapon.Deactivate_Anim:
		change_weapon(next_weapon)
		
	if anim_name == current_weapon.Shoot_Anim && current_weapon.Auto_Fire == true:
		if Input.is_action_pressed("shoot"):
			shoot()
		
func shoot():
	if current_weapon.Current_Ammo != 0:
		if !animation_player.is_playing():
			animation_player.play(current_weapon.Shoot_Anim)
			current_weapon.Current_Ammo -= 1
			emit_signal("Update_Ammo",[current_weapon.Current_Ammo, current_weapon.Reserve_Ammo])
			var camera_collision = get_camera_collision()
			
			match current_weapon.Type:
				NULL:
					print("Weapon Type Not Chosen")
				HITSCAN:
					hit_scan_collision(camera_collision)
				PROJECTILE:
					pass
	else:
		reload()

func reload():
	if current_weapon.Current_Ammo == current_weapon.Magazine:
		return
	elif !animation_player.is_playing():
		if current_weapon.Reserve_Ammo != 0:
			animation_player.play(current_weapon.Reload_Anim)
			var Reload_Ammount = min(current_weapon.Magazine - current_weapon.Current_Ammo, current_weapon.Magazine, current_weapon.Reserve_Ammo)
			
			current_weapon.Current_Ammo = current_weapon.Current_Ammo + Reload_Ammount
			current_weapon.Reserve_Ammo = current_weapon.Reserve_Ammo - Reload_Ammount
			emit_signal("Update_Ammo",[current_weapon.Current_Ammo, current_weapon.Reserve_Ammo])
		else:
			animation_player.play(current_weapon.Ooa_Anim)

func get_camera_collision() -> Vector3:
	var camera = get_viewport().get_camera_3d()
	var viewport = get_viewport().get_size()
	var ray_origin = camera.project_ray_origin(viewport/2)
	var ray_end = ray_origin + camera.project_ray_normal(viewport/2) * current_weapon.Weapon_Range
	var new_intersection = PhysicsRayQueryParameters3D.create(ray_origin,ray_end)
	var intersection = get_world_3d().direct_space_state.intersect_ray(new_intersection)
	
	if not intersection.is_empty():
		var col_point = intersection.position
		return col_point
	else:
		return ray_end

func hit_scan_collision(col_point: Vector3):
	# gets variables from previous camera fuction and calculates in order to setup hitscan 
	var bullet_direction = (col_point - bullet_point.get_global_transform().origin).normalized()
	var new_intersection = PhysicsRayQueryParameters3D.create(bullet_point.get_global_transform().origin, col_point + bullet_direction * 2)
	var bullet_collision = get_world_3d().direct_space_state.intersect_ray(new_intersection)
	# calls damage function
	if bullet_collision:
		hit_scan_damage(bullet_collision.collider)

func hit_scan_damage(collider):
	#finds enemy through grouping and 
	if collider.is_in_group("Enemy") and collider.has_method("hit_succesfull"):
		collider.hit_succesfull(current_weapon.Damage)
