# Spinner.gd
extends Node3D

var is_spinning = false
var spin_speed = 0.0
var target_speed = 0.0
var deceleration = 0.1

func _ready():
	pass

func _process(delta):
	if is_spinning:
		spin_speed = lerp(spin_speed, target_speed, deceleration * delta)
		if abs(spin_speed - target_speed) < 0.01:
			spin_speed = target_speed
			is_spinning = false
		rotate_y(spin_speed * delta)

func spin():
	is_spinning = true
	spin_speed = 10.0
	target_speed = 0.0
