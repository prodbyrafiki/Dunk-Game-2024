# MainGame.gd
extends Node3D

@export var player: Node3D
@export var spinner_scene: PackedScene

var spinner: Node3D

func _ready():
	setup_spinner()

func setup_spinner():
	spinner = spinner_scene.instance()
	add_child(spinner)
	spinner.global_transform.origin = Vector3(0, 1, 0) # Position the spinner in the scene
