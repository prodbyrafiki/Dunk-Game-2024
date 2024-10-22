extends Area3D

var health = 5

func hit_succesfull(Damage):
	health -= Damage
	print("Target Health: " + str(health))
	if health <= 0:
		queue_free()
