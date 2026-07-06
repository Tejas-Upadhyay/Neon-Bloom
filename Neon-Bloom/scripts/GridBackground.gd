extends Node2D

func _ready():
	queue_redraw()

func _draw():
	var w = 6000.0
	var h = 6000.0
	var grid_size = 100.0

	var x = 0.0
	while x <= w:
		var is_major = int(x / grid_size) % 5 == 0
		var alpha = 0.12 if is_major else 0.04
		var c = Color(0.1, 0.8, 0.7, alpha)
		var width = 2.0 if is_major else 1.0
		draw_line(Vector2(x, 0), Vector2(x, h), c, width)
		x += grid_size

	var y = 0.0
	while y <= h:
		var is_major = int(y / grid_size) % 5 == 0
		var alpha = 0.12 if is_major else 0.04
		var c = Color(0.1, 0.8, 0.7, alpha)
		var width = 2.0 if is_major else 1.0
		draw_line(Vector2(0, y), Vector2(w, y), c, width)
		y += grid_size

	var glow = Color(0.0, 1.0, 0.8, 0.15)
	var bright = Color(0.0, 1.0, 0.8, 0.4)
	var bw = 6.0
	draw_line(Vector2(bw, 0), Vector2(bw, h), bright, bw)
	draw_line(Vector2(w - bw, 0), Vector2(w - bw, h), bright, bw)
	draw_line(Vector2(0, bw), Vector2(w, bw), bright, bw)
	draw_line(Vector2(0, h - bw), Vector2(w, h - bw), bright, bw)

	draw_line(Vector2(0, 0), Vector2(0, h), glow, 20)
	draw_line(Vector2(w, 0), Vector2(w, h), glow, 20)
	draw_line(Vector2(0, 0), Vector2(w, 0), glow, 20)
	draw_line(Vector2(0, h), Vector2(w, h), glow, 20)
