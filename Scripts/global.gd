extends Node

var player : CharacterBody3D = null


func _input(event):
	if event.is_action_pressed("return"):
		get_tree().change_scene_to_file("res://Node/main_menu.tscn")
		
	if event.is_action_released("return"):
		Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
