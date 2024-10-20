extends CharacterBody3D

# nodes
@onready var pivot = $neck/head
@onready var camera = $neck/head/eye/Camera3D
@onready var eyes = $neck/head/eye
@onready var standing_collision_shape = $StandingCollisionShape
@onready var crouching_collision_shape = $CrouchingCollisionShape
@onready var ray_cast_3d = $CrouchingRay
@onready var neck = $neck
@onready var camera_3d = $neck/head/eye/Camera3D
@onready var gun_anim = $neck/head/eye/Camera3D/Weapons_Manager/Weapons_Rig/AnimationPlayer

@onready var gun_barrel = $neck/head/eye/Camera3D/Weapons_Manager/Weapons_Rig/malorian_pivot/Gun/RayCast3D
@onready var ledge_vertical_detection = $neck/head/eye/LedgeDetect/LedgeVerticalDetection
@onready var ledge_player_detect = $neck/head/eye/LedgeDetect/LedgePlayerDetect


#interaction







@export_category("Movement")
var current_speed = 5.0
@export var sprinting_speed = 12.0
@export var walking_speed = 9.0
@export var crouching_speed = 7.0
@export var JUMP_VELOCITY = 5.0

# input var
var sensitivity = 0.003
var direction = Vector3.ZERO

var free_look_tilt = 6


# Dash Variables
var dashing: bool = false
var can_dash: bool = true
@export var dash_duration: float = 0.2
@export var dash_cooldown: float = 0.8
var can_reload_dash: bool = false
@export var dash_speed: float = 40.0
@onready var dash_timer = $DashTimer
var cam_dash_tween: Tween




var lerp_speed = 10.0
var crouching_depth = -0.5


#states
var walking = false
var sprinting = false
var crouching = false
var free_looking = false
var sliding = false

# slide var

var slide_timer = 0.0
var slide_timer_max = 1.0
var slide_speed = 15
var slide_vector = Vector2.ZERO


# head bobbing var
const head_bobbing_sprinting_speed = 22.0
const head_bobbing_walking_speed = 14.0
const head_bobbing_crouching_speed = 10.0

const head_bobbing_spriting_intensity = 0.2
const head_bobbing_walking_intensity = 0.1
const head_bobbing_crouching_intensity = 0.05

var head_bobbing_vector = Vector2.ZERO
var head_bobbing_index = 0.0
var head_bobbing_current_intesity = 0.0

#var gun_bobbing_vector = Vector2.ZERO
#const head_bobbing_gun_intensity = 0.1

var bullet = load("res://Node/bullet.tscn")
var instance


signal player_hit
const HIT_STAGGER = 8.0



# Get the gravity from the project settings to be synced with RigidBody nodes.
var gravity = ProjectSettings.get_setting("physics/3d/default_gravity")

func _ready():
	pass
	
func _input(event):
	if event.is_action_pressed("exit"):
		get_tree().quit()

func _unhandled_input(event):
	
	
	if event is InputEventMouseMotion:
		Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	elif event.is_action_pressed("ui_cancel"):
		Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
	
	if Input.get_mouse_mode() == Input.MOUSE_MODE_CAPTURED:
		if event is InputEventMouseMotion:
			if free_looking:
				neck.rotate_y(-event.relative.x * sensitivity / 2)
				neck.rotation.y = clamp(neck.rotation.y, deg_to_rad(-120), deg_to_rad(120))
			else:
			
				pivot.rotate_y(-event.relative.x * sensitivity / 2)
				camera.rotate_x(-event.relative.y * sensitivity / 4)
				camera.rotation.x = clamp(camera.rotation.x, deg_to_rad(-89), deg_to_rad(89))
				camera.rotation.y = clamp(camera.rotation.y, deg_to_rad(0), deg_to_rad(0))
				

		

	
	
	
			
			

func _physics_process(delta):

	#movement input get
	var input_dir = Input.get_vector("move_left", "move_right", "move_forward", "move_back")
	
	if input_dir.x < 0:
		camera_3d.rotation.z = lerp(camera_3d.rotation.z, deg_to_rad(5.0), delta * lerp_speed)
	else:
		camera_3d.rotation.z = lerp(camera_3d.rotation.z,0.0, delta * lerp_speed)
	
	if input_dir.x > 0:
		camera_3d.rotation.z = lerp(camera_3d.rotation.z, deg_to_rad(-5.0), delta * lerp_speed)	
	else:
		camera_3d.rotation.z = lerp(camera_3d.rotation.z,0.0, delta * lerp_speed)
	
	# handle movement 
	
	# Crouchinng 
	
	if Input.is_action_pressed("crounch") && is_on_floor():
		current_speed = lerp(current_speed, crouching_speed, delta * lerp_speed)
		pivot.position.y = lerp(pivot.position.y, crouching_depth, delta*lerp_speed)
		
		standing_collision_shape.disabled = true
		crouching_collision_shape.disabled = false
		
			
		# Slide Begin Logic
		if sprinting && input_dir != Vector2.ZERO:
			sliding = true
			slide_timer = slide_timer_max
			free_looking = true 
			
		
		walking = false
		sprinting = false
		crouching = true
	elif Input.is_action_just_released("crounch"):
			slide_timer = 0
			sliding = false
	
	elif !ray_cast_3d.is_colliding():
		
	# Standing
		standing_collision_shape.disabled = false
		crouching_collision_shape.disabled = true
		pivot.position.y = lerp(pivot.position.y, 0.0 , delta*lerp_speed)
		
			

	# Sprinting
		if Input.is_action_pressed("sprint"):
			current_speed = lerp(current_speed, sprinting_speed, delta * lerp_speed)
			walking = false
			sprinting = true
			crouching = false
		else:
	# Walking
			current_speed = lerp(current_speed, walking_speed, delta * lerp_speed)
			walking = true
			sprinting = false
			crouching = false
			
			
	# Handle Free Look
	
	if Input.is_action_pressed("free_look"):
		free_looking = true
		camera_3d.rotation.z = -deg_to_rad(neck.rotation.y * free_look_tilt)
		
	else:
		free_looking = false
		neck.rotation.y = lerp(neck.rotation.y, 0.0, delta * lerp_speed)
		camera_3d.rotation.z = lerp(camera_3d.rotation.z, 0.0, delta * lerp_speed)
		
		

	# Handle Sliding Logic
	
	if sliding:
		slide_timer -= delta
		if slide_timer <= 0:
			sliding = false
			free_looking = false

		
#Handle Shooting

	#if Input.is_action_pressed("shoot"):
		#shoot()

		

			
	# handle head bob
	if sprinting:
		head_bobbing_current_intesity = head_bobbing_spriting_intensity
		head_bobbing_index += head_bobbing_sprinting_speed * delta
	elif walking:
		head_bobbing_current_intesity = head_bobbing_walking_intensity
		head_bobbing_index += head_bobbing_walking_speed * delta
	elif crouching:
		head_bobbing_current_intesity = head_bobbing_crouching_intensity
		head_bobbing_index += head_bobbing_crouching_speed * delta
		
	if is_on_floor() && input_dir !=Vector2.ZERO:
		head_bobbing_vector.y = sin(head_bobbing_index)
		head_bobbing_vector.x = sin(head_bobbing_index/2)+0.5
		
		# Makeshift Gun Bobbing
		#gun_bobbing_vector.y = sin(head_bobbing_walking_speed*delta)
		#gun_bobbing_vector.x = sin((head_bobbing_walking_speed*delta)/2)+0.5
		#

		eyes.position.y = lerp(eyes.position.y, head_bobbing_vector.y*(head_bobbing_current_intesity/2.0), delta*lerp_speed)
		eyes.position.x = lerp(eyes.position.x, head_bobbing_vector.x*(head_bobbing_current_intesity/2.0), delta*lerp_speed)
		
	else:
		eyes.position.y = lerp(eyes.position.y, 0.0, delta*lerp_speed)
		eyes.position.x = lerp(eyes.position.x, 0.0, delta*lerp_speed)

	if ledge_vertical_detection.is_colliding() && ledge_player_detect.is_colliding() and not is_on_floor():
		velocity.y = 0
	
	if ledge_vertical_detection.is_colliding() && ledge_player_detect.is_colliding() and Input.is_action_pressed("jump"):
		velocity.y = JUMP_VELOCITY * 1.5
	
		print("Hello ")
		
		#bool for ledge grab
		#half velocity
	# Add the gravity.
	elif not is_on_floor():
		velocity.y -= gravity * delta

	# Handle jump.
	if Input.is_action_just_pressed("jump") and is_on_floor():
		velocity.y = velocity.y + JUMP_VELOCITY
		
		
	if Input.is_action_just_pressed("dash") and not dashing and can_dash:
		dashing = true 
		can_dash = false
		dash_timer.start(dash_duration)
		camera_zoom_out(dash_duration)
		velocity.y = 0.0
		var dash_direction = (pivot.transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()
		velocity = dash_direction * dash_speed
		print("work")
		can_dash = true
		
		#if want to make only sideways dash then add a if check for whether there is input from forward or back and edit


	# Get the input direction and handle the movement/deceleration.
	# As good practice, you should replace UI actions with custom gameplay actions.


	var direction = (pivot.transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()
	

	if direction && is_on_floor() && not dashing:
		velocity.x = direction.x * current_speed
		velocity.z = direction.z * current_speed
		
	elif not dashing:
		velocity.x = lerp(velocity.x, direction.x * current_speed, 0.05)
		velocity.z = lerp(velocity.z, direction.z * current_speed, 0.05)
	
	if sliding:
		current_speed = (slide_timer + 0.4) * slide_speed
		
	else:
		if is_on_floor():
			velocity.x = lerp(velocity.x, 0.0, 0.1)
			velocity.z = lerp(velocity.z, 0.0, 0.1)
		else:
			velocity.x = lerp(velocity.x, 0.0, 0.01)
			velocity.z = lerp(velocity.z, 0.0, 0.01)
		
#Ablilites

	move_and_slide()
	
	
#func shoot():
	#
	#if !gun_anim.is_playing():
		#gun_anim.play("malorian_shoot")
		#instance = bullet.instantiate()
		#instance.position = gun_barrel.global_position
		#instance.transform.basis = gun_barrel.global_transform.basis
		#get_parent().add_child(instance)


func camera_zoom_out(duration: float) -> void:
	if cam_dash_tween and cam_dash_tween.is_running():	
		cam_dash_tween.kill()
	
	if dashing:
		cam_dash_tween = create_tween().set_ease(Tween.EASE_IN_OUT).set_trans(Tween.TRANS_CUBIC)
		cam_dash_tween.tween_property(camera, "fov", 90.0, 0.3)
		cam_dash_tween.tween_interval(duration-0.2)
		cam_dash_tween.tween_property(camera, "fov", 75.0, 0.4)


func _on_dash_timer_timeout() -> void:
	velocity.y = 0.0
	dashing = false
	print("balah")


func _on_dash_cooldown_timeout():
	can_reload_dash = true
	
func hit(dir):
	emit_signal("player_hit")
	velocity += dir * HIT_STAGGER
