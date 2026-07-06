extends Area2D

@export var plant_type := "organic"
@export var growth_rate := 20.0

var current_growth := 0.0
var max_growth := 100.0
var is_grown := false
var collected := false

var type_colors = {
	"organic": Color(0.2, 1.0, 0.4),
	"synthetic": Color(0.2, 0.6, 1.0),
	"data": Color(0.8, 0.2, 1.0)
}

func _ready():
	add_to_group("plant")
	queue_redraw()

func _draw():
	var base_color = type_colors.get(plant_type, Color(0.2, 1.0, 0.6))
	var pct = current_growth / max_growth if not is_grown else 1.0
	var radius = 2.0 + pct * 10.0

	var c = Color(base_color.r * (0.6 + pct * 0.4), base_color.g * (0.6 + pct * 0.4), base_color.b * (0.6 + pct * 0.4), 0.5 + pct * 0.5)
	if is_grown:
		c = Color(base_color.r * 1.8, base_color.g * 1.8, base_color.b * 1.8, 1.0)

	draw_circle(Vector2.ZERO, radius + 8, Color(c.r, c.g, c.b, 0.15))
	draw_circle(Vector2.ZERO, radius, c)

	if is_grown:
		var pulse = sin(Time.get_ticks_msec() * 0.005) * 0.15 + 0.15
		draw_circle(Vector2.ZERO, radius + 4 + pulse, Color(c.r, c.g, c.b, 0.2))

func _process(delta):
	if is_grown or collected:
		return

	var growth_mult = 1.0 + GameManager.upgrades.get("photosynthesis", 0) * 0.3
	current_growth += growth_rate * growth_mult * delta

	var pct = current_growth / max_growth
	if current_growth >= max_growth:
		is_grown = true

	queue_redraw()

func _on_body_entered(body):
	if is_grown and not collected and body.is_in_group("player"):
		collected = true
		GameManager.add_score(15)
		var amount = 3 + int(GameManager.wave * 0.5)
		GameManager.add_resource(plant_type, amount)
		SoundFX.play("collect", -6.0)

		match plant_type:
			"organic":
				var heal_amt = 15 + GameManager.upgrades.get("health", 0) * 5
				GameManager.heal_player(heal_amt)
			"synthetic":
				GameManager.change_power(40.0)
			"data":
				GameManager.add_memory(25.0)

		if body.has_method("spawn_floating_text"):
			body.spawn_floating_text("+%d %s" % [amount, plant_type.capitalize()], global_position, type_colors[plant_type])

		var tween = create_tween()
		tween.tween_property(self, "scale", Vector2(1.5, 1.5), 0.15)
		tween.parallel().tween_property(self, "modulate", Color(1, 1, 1, 0), 0.2)
		tween.parallel().tween_property(self, "position", position + Vector2(0, -20), 0.2)
		tween.tween_callback(queue_free)
