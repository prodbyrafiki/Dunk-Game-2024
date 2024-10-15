extends CharacterBody3D

@onready var navigation_agent: NavigationAgent3D = $NavigationAgent3D
@onready var player_body = get_node("/root/World/Enviroment/player")
@onready var animation_player = $AnimationPlayer
@onready var attack_timer = $AttackTimer

var target: CharacterBody3D = null
var acceleration: Vector3 = Vector3.ZERO
var player_position: Vector3
var player: CharacterBody3D = null

var is_attacking = false 

const ATTACK_RANGE = 2.5

var player_path: NodePath

enum State {
	CHASE,
	ATTACK
}

var current_state: State = State.CHASE  # Initial state set to "Chase"

@export_category("Movement")
@export var speed: float = 7.0

func _ready():
	if player_path:
		player = get_node_or_null(player_path) as CharacterBody3D
	else:
		player = player_body


func _process(delta: float) -> void:
	if player:
		match current_state:
			State.CHASE:
				navigation_agent.set_target_position(player.global_transform.origin)
				var next_nav_point = navigation_agent.get_next_path_position()
				velocity = (next_nav_point - global_transform.origin).normalized() * speed

				var player_position = player.global_transform.origin
				player_position.y = global_transform.origin.y  # Prevent vertical tilt
				look_at(player_position, Vector3.UP)
				
				# Play walk animation only if it's not already playing
				if not animation_player.is_playing() or animation_player.current_animation != "Walk":
					animation_player.play("Walk")

				if _target_in_range() and not is_attacking:
					_start_attack()

			State.ATTACK:
				if _target_in_range() and is_attacking:
					var player_position = player.global_transform.origin
					player_position.y = global_transform.origin.y
					look_at(player_position, Vector3.UP)
					velocity = Vector3.ZERO  # Stop movement during attack
				else:
					current_state = State.CHASE
		
		move_and_slide()

func _target_in_range() -> bool:
	return global_position.distance_to(player.global_position) < ATTACK_RANGE
	
func _start_attack() -> void:
	is_attacking = true
	animation_player.play("Attack1")
	current_state = State.ATTACK
	attack_timer.start()

func _on_attack_timer_timeout() -> void:
	print("jigas")
	is_attacking = false
	current_state = State.CHASE
	

func _hit_finished():
	if global_position.distance_to(player.global_position) < ATTACK_RANGE + 1.0:
		var dir = global_position.direction_to(player.global_position)
		player.hit(dir)
