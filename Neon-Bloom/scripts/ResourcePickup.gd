extends Area2D

@export var resource_type: String = "organic"
@export var amount: int = 1
var float_phase: float = 0.0
var lifetime: float = 0.0
var max_lifetime: float = 20.0

var type_colors = {
	"organic": Color(0.2, 1.0, 0.4),
	"synthetic": Color(0.2, 0.6, 1.0),
	"data": Color(0.8, 0.2, 1.0)
}

func _ready():
	add_to_group("resource")
	float_phase = randf() * TAU
	queue_redraw()

func initialize(type: String, amt: int):
	resource_type = type
	amount = amt
	queue_redraw()

func _draw():
	var color = type_colors.get(resource_type, Color(1, 1, 1))
	draw_circle(Vector2.ZERO, 12, Color(color.r, color.g, color.b, 0.2))
	var sz = 6.0
	var points = PackedVector2Array([
		Vector2(0, -sz),
		Vector2(sz * 0.5, 0),
		Vector2(0, sz),
		Vector2(-sz * 0.5, 0)
	])
	draw_colored_polygon(points, color)
	draw_circle(Vector2.ZERO, 3, Color(1, 1, 1, 0.6))

func _process(delta):
	float_phase += delta * 3.0
	lifetime += delta
	position.y += sin(float_phase) * delta * 8.0
	rotation += delta * 1.8

	if lifetime > max_lifetime * 0.8:
		var fade = 1.0 - (lifetime - max_lifetime * 0.8) / (max_lifetime * 0.2)
		modulate.a = fade
	if lifetime >= max_lifetime:
		queue_free()

func collect(player):
	GameManager.add_resource(resource_type, amount)
	GameManager.add_score(5)
	if player.has_method("spawn_floating_text"):
		var color = type_colors.get(resource_type, Color(1, 1, 1))
		player.spawn_floating_text("+%d %s" % [amount, resource_type.capitalize()], global_position, color)
	SoundFX.play("collect", -10.0)
	queue_free()

func _on_body_entered(body):
	if body.is_in_group("player"):
		collect(body)
