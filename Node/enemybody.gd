extends CharacterBody3D
# Nodes
@onready var navigation_agent: NavigationAgent3D = $NavigationAgent3D
@onready var player_body = get_node("/root/World/Enviroment/player")
@onready var animation_player = $AnimationPlayer
@onready var attack_timer = $AttackTimer
@onready var head_collison = $HeadCollison
var target: CharacterBody3D = null
var acceleration: Vector3 = Vector3.ZERO
var player_position: Vector3
var player: CharacterBody3D = null
var player_path: NodePath
# Interaction Variables
var is_attacking = false 
var health = 100
const ATTACK_RANGE = 2.5
# State Machine
enum State {
	CHASE,
	ATTACK,
	DEATH,
}

var current_state: State = State.CHASE  # Initial state set to "Chase"
# Movement Variables
@export_category("Movement")
@export var speed: float = 7.0

func _ready():
	# Sets player character as target 
	if player_path:
		player = get_node_or_null(player_path) as CharacterBody3D
	else:
		player = player_body

func _process(delta: float) -> void:
	# Handles Enemy State Machine and swtiches between states
	if player:
		match current_state:
			State.CHASE:
				# Chase Logic
				navigation_agent.set_target_position(player.global_transform.origin)
				var next_nav_point = navigation_agent.get_next_path_position()
				velocity = (next_nav_point - global_transform.origin).normalized() * speed
				var player_position = player.global_transform.origin
				player_position.y = global_transform.origin.y  # Prevent vertical tilt
				look_at(player_position, Vector3.UP)
# Sets Animation
				if not animation_player.is_playing() or animation_player.current_animation != "Walk":
					animation_player.play("Walk")

				if _target_in_range() and not is_attacking:
					_start_attack()

			State.ATTACK:
				# Attack logic
				if _target_in_range() and is_attacking:
					var player_position = player.global_transform.origin
					player_position.y = global_transform.origin.y
					look_at(player_position, Vector3.UP)
					velocity = Vector3.ZERO  # Stop movement during attack
				else:
					current_state = State.CHASE

			State.DEATH:
				# Enemy is dead, do nothing
				velocity = Vector3.ZERO  # Ensure no movement after death
				return  # Skip further processing

		move_and_slide()

func _target_in_range() -> bool:
	return global_position.distance_to(player.global_position) < ATTACK_RANGE

func _start_attack() -> void:
	is_attacking = true
	animation_player.play("Attack1")
	current_state = State.ATTACK
	attack_timer.start()

func _on_attack_timer_timeout() -> void:
	is_attacking = false
	current_state = State.CHASE

func _hit_finished():
	if global_position.distance_to(player.global_position) < ATTACK_RANGE + 1.0:
		var dir = global_position.direction_to(player.global_position)
		player.hit(dir)

func hit_succesfull(Damage):
	# When enemy takes damage, reduce health
	health -= Damage
	print("Target Health: " + str(health))
	if health <= 0:
		_enter_death_state()

func _enter_death_state():
	# Transition to the death state, play death animation, and queue free after delay
	current_state = State.DEATH
	animation_player.play("Death1")
	await get_tree().create_timer(0.875).timeout
	queue_free()
