extends Node2D

var plant_scene = preload("res://scenes/plant/Plant.tscn")

func _unhandled_input(event):
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		spawn_plant(get_global_mouse_position())

func spawn_plant(pos: Vector2):
	if plant_scene:
		var plant = plant_scene.instantiate()
		plant.position = pos
		add_child(plant)
