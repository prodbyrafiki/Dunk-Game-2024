

extends Control


@export var bkg_color: Color
@export var line_color: Color 

@export var outer_radius = 256.0
@export var inner_radius = 64.0
@export var line_width = 4.0

func _draw():
	draw_circle(Vector2.ZERO, outer_radius, bkg_color)


func _process(delta):
	queue_redraw()
