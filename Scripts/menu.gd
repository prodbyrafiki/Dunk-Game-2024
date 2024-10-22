extends Control
# Node
@onready var play_button = $ColorRect/MarginContainer/VBoxContainer/Play
@onready var options_button = $ColorRect/MarginContainer/VBoxContainer/Options
@onready var exit_button = $ColorRect/MarginContainer/VBoxContainer/Exit

func _on_play_pressed():
	get_tree().change_scene_to_file("res://Node/world.tscn")

func _on_options_pressed():
	print("load options menu")

func _on_exit_pressed():
	get_tree().quit()  

func handle_connecting_signals() -> void:
	play_button.button_down.connect(_on_play_pressed)
	options_button.button_down.connect(_on_options_pressed)
	exit_button.button_down.connect(_on_exit_pressed)
