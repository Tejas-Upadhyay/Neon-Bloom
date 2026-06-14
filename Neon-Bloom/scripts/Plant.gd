extends Area2D

@export var growth_rate = 30.0
var current_growth = 0.0
var max_growth = 100.0
var is_grown = false

@onready var sprite = $Sprite2D

func _ready():
	sprite.scale = Vector2(0.02, 0.02)
	sprite.modulate = Color(0.5, 0.5, 0.5)

func _process(delta):
	if not is_grown:
		current_growth += growth_rate * delta
		var scale_val = clamp((current_growth / max_growth) * 0.1, 0.02, 0.1)
		sprite.scale = Vector2(scale_val, scale_val)
		if current_growth >= max_growth:
			is_grown = true
			sprite.modulate = Color(1, 1, 1) # Full color when grown

func _on_body_entered(body):
	if is_grown and body.is_in_group("player"):
		body.collect_plant()
		queue_free()
