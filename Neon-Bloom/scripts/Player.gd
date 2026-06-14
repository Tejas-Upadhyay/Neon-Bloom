extends CharacterBody2D

@export var speed = 400.0
var collected_plants = 0

func _physics_process(delta):
	var direction = Input.get_vector("ui_left", "ui_right", "ui_up", "ui_down")
	velocity = direction * speed
	move_and_slide()

func collect_plant():
	collected_plants += 1
	var ui = get_tree().get_first_node_in_group("ui")
	if ui:
		ui.update_score(collected_plants)
