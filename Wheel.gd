extends Area3D

@onready var player = $"../player"
var player_position 



# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	

	
	player_position = player.position
	look_at(player_position)
	rotation.x = clamp(player_position.y, deg_to_rad(-89), deg_to_rad(0))

func _on_body_entered(body):
	queue_free()
	print("Helloworld")
