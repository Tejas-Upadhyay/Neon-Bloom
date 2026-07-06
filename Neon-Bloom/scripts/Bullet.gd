extends Area2D

var speed := 800.0
var direction := Vector2.RIGHT
var damage := 25
var has_hit := false
var is_enemy_bullet := false

func _ready():
	if is_enemy_bullet:
		collision_mask = 1
		collision_layer = 0
	queue_redraw()

func _draw():
	if is_enemy_bullet:
		draw_circle(Vector2.ZERO, 14, Color(1.0, 0.15, 0.15, 0.25))
		draw_circle(Vector2.ZERO, 6, Color(1.0, 0.2, 0.2))
	else:
		draw_circle(Vector2.ZERO, 14, Color(1.0, 0.85, 0.0, 0.25))
		draw_circle(Vector2.ZERO, 6, Color(1.0, 0.85, 0.0))

func _physics_process(delta):
	position += direction * speed * delta

func _on_body_entered(body):
	if has_hit:
		return
	if is_enemy_bullet:
		if body.is_in_group("player"):
			has_hit = true
			GameManager.damage_player(damage)
			spawn_impact()
			queue_free()
		elif not body.is_in_group("enemy"):
			has_hit = true
			spawn_impact()
			queue_free()
	else:
		if body.is_in_group("enemy"):
			has_hit = true
			body.take_damage(damage)
			spawn_impact()
			queue_free()
		elif not body.is_in_group("player"):
			has_hit = true
			spawn_impact()
			queue_free()

func spawn_impact():
	for i in range(6):
		var spark = ColorRect.new()
		spark.size = Vector2(4, 4)
		spark.global_position = global_position
		var c = Color(1.0, 0.2, 0.2) if is_enemy_bullet else Color(1.0, 0.85, 0.0)
		spark.color = c
		var angle = randf_range(0, TAU)
		var dist = randf_range(20, 60)
		get_tree().current_scene.add_child(spark)
		var tween = create_tween()
		tween.set_parallel(true)
		tween.tween_property(spark, "global_position", global_position + Vector2(cos(angle), sin(angle)) * dist, 0.2)
		tween.tween_property(spark, "color:a", 0.0, 0.2)
		tween.tween_callback(spark.queue_free)

func _on_visible_on_screen_notifier_2d_screen_exited():
	if not has_hit:
		queue_free()
