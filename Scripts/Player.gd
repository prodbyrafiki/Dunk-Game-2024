extends CharacterBody3D

# nodes
@onready var pivot = $head
@onready var camera = $head/Camera3D
@onready var standing_collision_shape = $StandingCollisionShape
@onready var crouching_collision_shape = $CrouchingCollisionShape
@onready var ray_cast_3d = $RayCast3D


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



#states
var walking = false
var sprinting = false
var crouching = false
var free_looking = false
var sliding = false


# Get the gravity from the project settings to be synced with RigidBody nodes.
var gravity = ProjectSettings.get_setting("physics/3d/default_gravity")

func _unhandled_input(event):
	if event is InputEventMouseMotion:
		Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	elif event.is_action_pressed("ui_cancel"):
		Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
	
	if Input.get_mouse_mode() == Input.MOUSE_MODE_CAPTURED:
		if event is InputEventMouseMotion:
			pivot.rotate_y(-event.relative.x * sensitivity / 2)
			camera.rotate_x(-event.relative.y * sensitivity / 4)
			camera.rotation.x = clamp(camera.rotation.x, deg_to_rad(-89), deg_to_rad(89))
			camera.rotation.y = clamp(camera.rotation.y, deg_to_rad(0), deg_to_rad(0))

func _physics_process(delta):
	
	# handle movement 
	
	# Crouchinng 
	
	if Input.is_action_pressed("crounch"):
		current_speed = crouching_speed
		pivot.position.y = lerp(pivot.position.y, 1.8 + crouching_depth, delta*lerp_speed)
		
		standing_collision_shape.disabled = true
		crouching_collision_shape.disabled = false
		
		walking = false
		sprinting = false
		crouching = true
	
	elif !ray_cast_3d.is_colliding():
		
	# Standing
		standing_collision_shape.disabled = false
		crouching_collision_shape.disabled = true
		pivot.position.y = lerp(pivot.position.y, 1.8 , delta*lerp_speed)
		
	# Sprinting
		if Input.is_action_pressed("sprint"):
			current_speed = sprinting_speed
			walking = false
			sprinting = true
			crouching = false
		else:
	# Walking
			current_speed = walking_speed
			walking = true
			sprinting = false
			crouching = false
			
			
	# Handle Free Look
	
	if Input.is_action_pressed("free_look"):
		free_looking = true
	else:
		free_looking = false
		
		
		
	# Add the gravity.
	if not is_on_floor():
		velocity.y -= gravity * delta

	# Handle jump.
	if Input.is_action_just_pressed("jump") and is_on_floor():
		velocity.y = JUMP_VELOCITY

	# Get the input direction and handle the movement/deceleration.
	# As good practice, you should replace UI actions with custom gameplay actions.
	var input_dir = Input.get_vector("move_left", "move_right", "move_forward", "move_back")
	var direction = (pivot.transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()
	if direction:
		velocity.x = direction.x * current_speed
		velocity.z = direction.z * current_speed
	else:
		velocity.x = move_toward(velocity.x, 0, current_speed)
		velocity.z = move_toward(velocity.z, 0, current_speed)

	move_and_slide()
