extends CharacterBody3D

# Player Nodes

@onready var head = $neck/head
@onready var standing_collision_shape = $standing_collision_shape
@onready var crouching_collision_shape = $crouching_collision_shape
@onready var ray_cast_3d = $RayCast3D
@onready var camera_3d = $neck/head/Camera3D
@onready var neck = $neck
@onready var wall_running_collision = $"wall running collision"


# Abilities

var global_abilities = ["double_jump", "dash", "sink", "lunge"]
var on_hand_abilities = []

# Speed Varibles

var current_speed = 5.0
const walking_speed = 15.0
const sprinting_speed = 15.0
const crounching_speed = 10.0

# States

var walking = false
var sprinting = false
var crouching = false
var moving_left = false
var moving_right = false
var sliding = false

# Movement Variables

const jump_velocity = 6
const double_jump_velocity = 10
const sink_velocity = 20
var crouch_depth = -0.5
var lerp_speed = 10.0
var lerp_rotation_speed = 10.0
var has_dashed = false

# Camera Variables

var left_move_tilt_ammount = 5
var right_move_tilt_ammount = -5
var time = 0

#Slide Variables
var slide_timer = 0.0
var slide_timer_max = 1.0
var slide_vector = Vector2.ZERO
var slide_speed = 40.0

# Wall Run Variables
var left_collision = false
var right_collision = false
var wall_collision = false
var wall_jump_direction
var is_wall_jumping = false
var wall_jump_velocity = 7
const wall_jump_duration = 0.1

# Dash Variables

const dash_velocity = 10
var dash_timer = 0.0
const dash_duration = 0.1
var dash_direction
var is_dashing = false

# Lunge Variables

var lunge_dir = Vector3()
var is_lunging = false
var lunge_velocity = 10
var lunge_duration = 0.2

# Input variables

const mouse_sens = 0.4
var direction = Vector3.ZERO

# Get the gravity from the project settings to be synced with RigidBody nodes.

var gravity = ProjectSettings.get_setting("physics/3d/default_gravity")

# Setting the Mouse Sensitivity

func _ready():
      Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)

# Mouse movement

func _input(event):
      if event is InputEventMouseMotion:
            rotate_y(deg_to_rad(-event.relative.x * mouse_sens))
            head.rotate_x(deg_to_rad(-event.relative.y * mouse_sens))
            head.rotation.x = clamp(head.rotation.x, deg_to_rad(-89), deg_to_rad(89))

# Physics Processes

func _physics_process(delta):
      $speedlines.material.set_shader_parameter("line_density", 0.0)
      
# Getting the Input Direction and Handling the Movement / Deceleration
      
      var input_dir = Input.get_vector("left", "right", "forward", "backward")
      
      if is_on_floor() and has_dashed:
            has_dashed = false
      
# Handling Movement States
      
# Crouching
      
      if Input.is_action_pressed("crounch") && is_on_floor():
            
            current_speed = crounching_speed
            head.position.y = lerp(head.position.y,crouch_depth, delta * lerp_speed)
            
            standing_collision_shape.disabled = true
            crouching_collision_shape.disabled = false
            
#Slide Logic
            
            if sprinting && input_dir != Vector2.ZERO:
                  slide_timer = slide_timer_max
                  sliding = true
                  slide_vector = input_dir
                  $speedlines.material.set_shader_parameter("line_density", 1.0)
            
            walking = false
            sprinting = false
            crouching = true
            
      elif !ray_cast_3d.is_colliding():
            
# Standing
            standing_collision_shape.disabled = false
            crouching_collision_shape.disabled = true
            head.position.y = lerp(head.position.y, 0.0, delta * lerp_speed)
            
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
                  #sprinting = false
                  crouching = false
      
#Handle left/right movement

      if is_on_floor():
            if Input.is_action_pressed("left") and not moving_right:
                  moving_left = true
                  camera_3d.rotation.z = lerp(camera_3d.rotation.z, deg_to_rad(left_move_tilt_ammount), delta * lerp_rotation_speed)
                  
            else:
                  moving_left = false
                  camera_3d.rotation.z = lerp(camera_3d.rotation.z, 0.0, delta * lerp_speed)

            if Input.is_action_pressed("right") and not moving_left:
                  moving_right = true
                  camera_3d.rotation.z = lerp(camera_3d.rotation.z, deg_to_rad(right_move_tilt_ammount), delta * lerp_rotation_speed)
                  
            else:
                  moving_right = false
                  camera_3d.rotation.z = lerp(camera_3d.rotation.z, 0.0, delta * lerp_speed)
                  
      else:
            camera_3d.rotation.z = lerp(camera_3d.rotation.z, 0.0, delta * lerp_speed)

#Handle Wall run

      if $"left collision".is_colliding() and not is_on_floor():
            left_collision = true
            wall_collision = true
            camera_3d.rotation.z = lerp(camera_3d.rotation.z, deg_to_rad(-20), delta * lerp_rotation_speed)
            
            if Input.is_action_just_pressed("ui_accept"):
                  $wall_jump_timer.start(wall_jump_duration)
                  is_wall_jumping = true
                  velocity.y = wall_jump_velocity
                  wall_jump_direction = transform.basis.x
      
      if $"right collision".is_colliding() and not is_on_floor():
            right_collision = true
            wall_collision = true
            camera_3d.rotation.z = lerp(camera_3d.rotation.z, deg_to_rad(20), delta * lerp_rotation_speed)
            
            if Input.is_action_just_pressed("ui_accept"):
                  $wall_jump_timer.start(wall_jump_duration)
                  is_wall_jumping = true
                  velocity.y = wall_jump_velocity
                  wall_jump_direction = -transform.basis.x
      
      if not $"right collision".is_colliding() and not $"left collision".is_colliding():
            wall_collision = false

#Handle sliding

      if sliding:
            slide_timer -= delta
            $speedlines.material.set_shader_parameter("line_density", 1.0)

            if slide_timer <= 0:
                  $speedlines.material.set_shader_parameter("line_density", 0.0)
                  sliding = false
                  crouching = false
                  sprinting = false

      #Handling the dash
      
      if not is_on_floor() and not is_dashing: #and not is_lunging:
            
# Add the gravity.
      
            if wall_collision and velocity.y < 0:
                  velocity.y -= gravity * delta / 2
                  
            elif not has_dashed:
                  velocity.y -= gravity * delta
            else:
                  velocity.y -= gravity * delta# / 2
                  $speedlines.material.set_shader_parameter("line_density", 1.0)

# Handle jump.

      if Input.is_action_just_pressed("ui_accept") and is_on_floor():
            velocity.y = jump_velocity
      
#lerp speed - will decellerate from whatever speed player is moving at
      
      direction = (transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()
      
#lerp speed for jumps IDK I HAVENT FIGURED IT OUT YET
      
      if sliding:
            direction = (transform.basis * Vector3(slide_vector.x, 0, slide_vector.y)).normalized()
      
# Tweaking the gravity to maintain horizontal momentum while using "dash"

      if direction and not is_dashing:
            if is_on_floor():
                  velocity.x = lerp(velocity.x, direction.x * current_speed, 0.2)
                  velocity.z = lerp(velocity.z, direction.z * current_speed, 0.2)
                  
            else:
                  velocity.x = lerp(velocity.x, direction.x * current_speed, 0.04)
                  velocity.z = lerp(velocity.z, direction.z * current_speed, 0.04)
                  
            if sliding && is_on_floor():
                  velocity.x = direction.x * slide_timer * slide_speed
                  velocity.z = direction.z * slide_timer * slide_speed
                  
      else:
            if is_on_floor():
                  velocity.x = lerp(velocity.x, 0.0, 0.1)
                  velocity.z = lerp(velocity.z, 0.0, 0.1)
            else:
                  velocity.x = lerp(velocity.x, 0.0, 0.01)
                  velocity.z = lerp(velocity.z, 0.0, 0.01)
      
      if is_dashing:
            time += delta
            velocity += dash_direction * -dash_velocity
            velocity.y = 0  # Keep the dash horizontal
            
      if is_lunging:
            time += delta
            velocity += lunge_dir * -lunge_velocity
            velocity.y = (lunge_dir * dash_velocity).z * 2
      
      if is_wall_jumping:
            velocity += wall_jump_direction * 2
      
      move_and_slide()
# Abilities

      if Input.is_action_just_pressed("ability"):
            print(on_hand_abilities)
            
            if len(on_hand_abilities) > 0:
                  
                  if on_hand_abilities[0] == "double_jump":
                        velocity.y = double_jump_velocity
                        print(on_hand_abilities[0])
                        on_hand_abilities.remove_at(0)
                        print(on_hand_abilities)
                        
                  elif on_hand_abilities[0] == "dash":
                        is_dashing = true
                        $dash_timer.start(dash_duration)
                        dash_direction = transform.basis.z
                        has_dashed = true
                        print(on_hand_abilities[0]) 
                        on_hand_abilities.remove_at(0)
                        print(on_hand_abilities)
                        
                  elif on_hand_abilities[0] == "sink":
                        # add sink code here
                        velocity.y = -sink_velocity
                        print(on_hand_abilities[0])
                        on_hand_abilities.remove_at(0)
                        print(on_hand_abilities)

                  elif on_hand_abilities[0] == "lunge":
                        is_lunging = true
                        $lunge_timer.start(lunge_duration)
                        lunge_dir = $neck/head.transform.basis.z
                        lunge_dir = transform.basis.z
                        print(on_hand_abilities[0])
                        on_hand_abilities.remove_at(0)
                        print(on_hand_abilities)
                        
                  else:
                        pass
                  
                  sprinting = true
      
# Switching Between Abilities
      
      if Input.is_action_just_pressed("switch"):
            on_hand_abilities.reverse()
            print(on_hand_abilities)

# On dash and lunge end funcitons: (Makes each ability stop on timer end)

func _dash_end():
      is_dashing = false
      velocity.y = 0
      $speedlines.material.set_shader_parameter("line_density", 0.0)

func _on_lunge_timer_timeout():
      is_lunging = false


func _on_wall_jump_timer_timeout():
      is_wall_jumping = false
