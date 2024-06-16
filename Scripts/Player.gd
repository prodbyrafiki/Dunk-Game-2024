extends CharacterBody3D

# nodes
@onready var pivot = $neck/head
@onready var camera = $neck/head/eye/Camera3D
@onready var eyes = $neck/head/eye
@onready var standing_collision_shape = $StandingCollisionShape
@onready var crouching_collision_shape = $CrouchingCollisionShape
@onready var ray_cast_3d = $RayCast3D
@onready var neck = $neck
@onready var camera_3d = $neck/head/eye/Camera3D
@onready var gun_anim = $AnimationPlayer

@onready var gun_barrel = $neck/head/eye/Camera3D/Gun/RayCast3D


#interaction





# speeds
var current_speed = 5.0
const sprinting_speed = 8.0
const walking_speed = 5.0
const crouching_speed = 3.0
var lerp_speed = 10.0
const JUMP_VELOCITY = 5.0
var crouching_depth = -0.5

# input var
var sensitivity = 0.003
var direction = Vector3.ZERO

var free_look_tilt = 6



#states
var walking = false
var sprinting = false
var crouching = false
var free_looking = false
var sliding = false

# slide var

var slide_timer = 0.0
var slide_timer_max = 1
var slide_speed = 10 


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


var bullet = load("res://Node/bullet.tscn")
var instance




# Get the gravity from the project settings to be synced with RigidBody nodes.
var gravity = ProjectSettings.get_setting("physics/3d/default_gravity")

func _ready():
	gun_anim.play("gun_activate")


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
	
	# handle movement 
	
	# Crouchinng 
	
	if Input.is_action_pressed("crounch") && is_on_floor():
		current_speed = lerp(current_speed, crouching_speed, delta * lerp_speed)
		pivot.position.y = lerp(pivot.position.y, crouching_depth, delta*lerp_speed)
		
		standing_collision_shape.disabled = true
		crouching_collision_shape.disabled = false
		
		if not is_on_floor():
			current_speed = JUMP_VELOCITY
		
		# Slide Begin Logic
		if sprinting && input_dir != Vector2.ZERO:
			sliding = true
			slide_timer = slide_timer_max
			free_looking = true 
		elif Input.is_action_just_released("crounch"):
			slide_timer = 0
			sliding = false
		
		walking = false
		sprinting = false
		crouching = true
	
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
		
		
		
#Handle Shooting

	if Input.is_action_pressed("shoot"):
		if !gun_anim.is_playing():
			gun_anim.play("shoot")
			instance = bullet.instantiate()
			instance.position = gun_barrel.global_position
			instance.transform.basis = gun_barrel.global_transform.basis
			get_parent().add_child(instance)
		
		
		
	# Handle Sliding Logic
	
	if sliding:
		slide_timer -= delta
		if slide_timer <= 0:
			sliding = false
			free_looking = false
			
			
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
		
	if is_on_floor() && !sliding && input_dir !=Vector2.ZERO:
		head_bobbing_vector.y = sin(head_bobbing_index)
		head_bobbing_vector.x = sin(head_bobbing_index/2)+0.5

		eyes.position.y = lerp(eyes.position.y, head_bobbing_vector.y*(head_bobbing_current_intesity/2.0), delta*lerp_speed)
		eyes.position.x = lerp(eyes.position.x, head_bobbing_vector.x*(head_bobbing_current_intesity/2.0), delta*lerp_speed)
	else:
		eyes.position.y = lerp(eyes.position.y, 0.0, delta*lerp_speed)
		eyes.position.x = lerp(eyes.position.x, 0.0, delta*lerp_speed)

	# Add the gravity.
	if not is_on_floor():
		velocity.y -= gravity * delta

	# Handle jump.
	if Input.is_action_just_pressed("jump") and is_on_floor():
		velocity.y = JUMP_VELOCITY
		sliding = false
		


	# Get the input direction and handle the movement/deceleration.
	# As good practice, you should replace UI actions with custom gameplay actions.


	direction = (pivot.transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()
	
		
	if sliding:
		current_speed = (slide_timer + 0.4) * slide_speed

	
	if direction:
		velocity.x = direction.x * current_speed
		velocity.z = direction.z * current_speed

	else:
		velocity.x = move_toward(velocity.x, 0, current_speed)
		velocity.z = move_toward(velocity.z, 0, current_speed)

	move_and_slide()
