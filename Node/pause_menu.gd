extends Control
# Pulls main
@onready var main = $"../../"



func _on_resume_pressed():
	main._pause_menu()
	
func _on_quit_pressed():
	get_tree().quit
