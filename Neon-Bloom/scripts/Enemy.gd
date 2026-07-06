extends CharacterBody2D

enum State { CHASE, ATTACK, PATROL, FLEE, CIRCLE }

var enemy_type := "Hydro Core"
var is_boss := false
var behavior_variant := "swarm"
var speed := 200.0
var health := 50
var max_health := 50
var damage := 10
var attack_cooldown := 1.0
var attack_timer := 0.0
var state := State.PATROL

var dash_timer := 0.0
var dash_interval := 2.0
var dash_duration := 0.3
var dash_pause := 0.5
var is_dashing := false
var is_dash_paused := false
var dash_elapsed := 0.0

var sniper_shoot_timer := 0.0
var circle_angle := 0.0
var circle_radius := 60.0
var circle_speed := 3.0

var patrol_angle := 0.0
var patrol_radius := 40.0
var patrol_origin := Vector2.ZERO

@onready var player := get_tree().get_first_node_in_group("player")

var resource_pickup_scene = preload("res://scenes/resource/ResourcePickup.tscn")
var bullet_scene = preload("res://scenes/bullet/Bullet.tscn")

var sector_colors = {
	"Hydro Core": Color(0.2, 1.0, 0.4),
	"Reactor Gardens": Color(0.2, 0.6, 1.0),
	"Cryo Labs": Color(0.8, 0.2, 1.0),
	"Observation Deck": Color(1.0, 0.15, 0.15)
}

func _ready():
	add_to_group("enemy")
	patrol_origin = global_position

	var roll = randf()
	if roll < 0.30:
		behavior_variant = "swarm"
	elif roll < 0.55:
		behavior_variant = "tank"
	elif roll < 0.80:
		behavior_variant = "sniper"
	else:
		behavior_variant = "dasher"

	_apply_variant_stats()
	max_health = health

func _apply_variant_stats():
	match behavior_variant:
		"swarm":
			speed *= 1.4
			health = int(health * 0.5)
			damage = max(1, int(damage * 0.6))
			attack_cooldown = 0.8
		"tank":
			speed *= 0.5
			health = int(health * 2.5)
			damage = int(damage * 1.3)
			attack_cooldown = 1.5
		"sniper":
			speed *= 0.9
			health = int(health * 0.8)
			damage = int(damage * 1.2)
			attack_cooldown = 1.5
		"dasher":
			speed *= 1.1
			health = int(health * 0.9)
			damage = int(damage * 1.1)
			attack_cooldown = 1.0

func _draw():
	var base_color = sector_colors.get(enemy_type, Color(1, 0.15, 0.15))
	var c = base_color
	var hp_pct = float(health) / float(max_health) if max_health > 0 else 0.0

	draw_circle(Vector2.ZERO, 14, Color(c.r, c.g, c.b, 0.2))
	var size = 8.0
	if is_boss:
		size = 18.0
		draw_circle(Vector2.ZERO, 22, Color(c.r, c.g, c.b, 0.15))

	match behavior_variant:
		"swarm":
			draw_circle(Vector2.ZERO, size * 0.7, c)
		"tank":
			var hs = size * 1.3
			draw_rect(Rect2(-hs, -hs, hs * 2, hs * 2), c)
			draw_rect(Rect2(-hs + 2, -hs + 2, (hs * 2 - 4), (hs * 2 - 4)), Color(0, 0, 0, 0.3))
		"sniper":
			draw_circle(Vector2.ZERO, size, c)
			draw_circle(Vector2.ZERO, size * 0.5, Color(0, 0, 0, 0.4))
			var angle = Time.get_ticks_msec() * 0.005
			draw_line(Vector2(-size * 1.2, 0), Vector2(size * 1.2, 0), c, 2.0)
			draw_line(Vector2(0, -size * 1.2), Vector2(0, size * 1.2), c, 2.0)
			if is_dashing:
				draw_circle(Vector2.ZERO, size * 1.8, Color(c.r, c.g, c.b, 0.15))
		"dasher":
			var tip = Vector2(size * 1.2, 0)
			var left = Vector2(-size * 0.6, size * 0.8)
			var right = Vector2(-size * 0.6, -size * 0.8)
			if player:
				var dir = global_position.direction_to(player.global_position)
				var a = dir.angle()
				tip = tip.rotated(a)
				left = left.rotated(a)
				right = right.rotated(a)
			draw_colored_polygon(PackedVector2Array([tip, left, right]), c)

	if hp_pct < 1.0:
		var bar_w = 20.0
		var bar_h = 3.0
		var bar_y = -14.0
		draw_rect(Rect2(-bar_w / 2, bar_y, bar_w, bar_h), Color(0.1, 0.1, 0.1, 0.7))
		draw_rect(Rect2(-bar_w / 2, bar_y, bar_w * hp_pct, bar_h), Color(c.r, c.g * 0.5, c.b * 0.5, 0.9))

func _process(delta):
	player = get_tree().get_first_node_in_group("player")

	if not player or GameManager.is_game_over:
		velocity = Vector2.ZERO
		move_and_slide()
		return

	var dir = global_position.direction_to(player.global_position)
	var dist = global_position.distance_to(player.global_position)

	queue_redraw()

	match behavior_variant:
		"swarm":
			_process_swarm(delta, dir, dist)
		"tank":
			_process_tank(delta, dir, dist)
		"sniper":
			_process_sniper(delta, dir, dist)
		"dasher":
			_process_dasher(delta, dir, dist)

func _process_swarm(delta, dir: Vector2, dist: float):
	match state:
		State.PATROL:
			patrol_angle += circle_speed * delta
			var target = patrol_origin + Vector2(cos(patrol_angle), sin(patrol_angle)) * patrol_radius
			velocity = global_position.direction_to(target) * speed * 0.5
			move_and_slide()
			if dist < 250:
				state = State.CHASE
		State.CHASE:
			velocity = dir * speed
			move_and_slide()
			if dist < circle_radius + 10:
				state = State.CIRCLE
				circle_angle = global_position.direction_to(player.global_position).angle() + PI
		State.CIRCLE:
			circle_angle += circle_speed * delta
			var orbit_target = player.global_position + Vector2(cos(circle_angle), sin(circle_angle)) * circle_radius
			velocity = global_position.direction_to(orbit_target) * speed
			move_and_slide()
			attack_timer += delta
			if attack_timer >= attack_cooldown and dist < 75:
				var defense = GameManager.upgrades.get("health", 0) * 2
				GameManager.damage_player(max(1, damage - defense))
				attack_timer = 0.0
			if dist > 120:
				state = State.CHASE
		State.ATTACK:
			velocity = Vector2.ZERO
			move_and_slide()
			attack_timer += delta
			if attack_timer >= attack_cooldown:
				if dist < 40:
					var defense = GameManager.upgrades.get("health", 0) * 2
					GameManager.damage_player(max(1, damage - defense))
				attack_timer = 0.0
			if dist > 55:
				state = State.CHASE

func _process_tank(delta, dir: Vector2, dist: float):
	match state:
		State.PATROL:
			state = State.CHASE
		State.CHASE:
			velocity = dir * speed
			move_and_slide()
			if dist < 35:
				state = State.ATTACK
				attack_timer = 0.0
		State.ATTACK:
			velocity = Vector2.ZERO
			move_and_slide()
			attack_timer += delta
			if attack_timer >= attack_cooldown:
				if dist < 40:
					var defense = GameManager.upgrades.get("health", 0) * 2
					GameManager.damage_player(max(1, damage - defense))
				attack_timer = 0.0
			if dist > 55:
				state = State.CHASE

func _process_sniper(delta, dir: Vector2, dist: float):
	match state:
		State.PATROL:
			state = State.CHASE
		State.CHASE:
			if dist > 300:
				velocity = dir * speed
			elif dist < 200:
				velocity = -dir * speed * 0.8
			else:
				velocity = dir.rotated(PI * 0.5) * speed * 0.3
			move_and_slide()
			sniper_shoot_timer += delta
			if sniper_shoot_timer >= 1.5:
				_fire_bullet(dir)
				sniper_shoot_timer = 0.0
			if dist < 150:
				state = State.FLEE
		State.FLEE:
			velocity = -dir * speed * 1.3
			move_and_slide()
			sniper_shoot_timer += delta
			if sniper_shoot_timer >= 1.5:
				_fire_bullet(dir)
				sniper_shoot_timer = 0.0
			if dist > 250:
				state = State.CHASE
		State.ATTACK:
			velocity = Vector2.ZERO
			move_and_slide()
			sniper_shoot_timer += delta
			if sniper_shoot_timer >= 1.5:
				_fire_bullet(dir)
				sniper_shoot_timer = 0.0
			if dist < 150:
				state = State.FLEE
			elif dist > 140:
				state = State.CHASE

func _process_dasher(delta, dir: Vector2, dist: float):
	match state:
		State.PATROL:
			state = State.CHASE
		State.CHASE:
			dash_timer += delta
			if is_dash_paused:
				velocity = Vector2.ZERO
				dash_elapsed += delta
				if dash_elapsed >= dash_pause:
					is_dash_paused = false
					dash_elapsed = 0.0
					dash_timer = 0.0
			elif is_dashing:
				velocity = dir * speed * 3.0
				dash_elapsed += delta
				if dash_elapsed >= dash_duration:
					is_dashing = false
					is_dash_paused = true
					dash_elapsed = 0.0
			else:
				velocity = dir * speed
				if dash_timer >= dash_interval:
					is_dashing = true
					dash_elapsed = 0.0
			move_and_slide()
			if dist < 35:
				state = State.ATTACK
				attack_timer = 0.0
				is_dashing = false
				is_dash_paused = false
				dash_elapsed = 0.0
		State.ATTACK:
			velocity = Vector2.ZERO
			move_and_slide()
			attack_timer += delta
			if attack_timer >= attack_cooldown:
				if dist < 40:
					var defense = GameManager.upgrades.get("health", 0) * 2
					GameManager.damage_player(max(1, damage - defense))
				attack_timer = 0.0
			if dist > 55:
				state = State.CHASE
				dash_timer = 0.0

func _fire_bullet(dir: Vector2):
	if not bullet_scene:
		return
	var bullet = bullet_scene.instantiate()
	bullet.global_position = global_position
	bullet.direction = dir
	bullet.rotation = dir.angle()
	bullet.damage = damage
	bullet.speed = 400.0
	bullet.is_enemy_bullet = true
	get_tree().current_scene.add_child(bullet)

func take_damage(amount: int):
	health -= amount
	SoundFX.play("hit", -8.0)
	spawn_damage_number(amount)
	modulate = Color(2, 2, 2, 1)
	await get_tree().create_timer(0.05).timeout
	if is_queued_for_deletion():
		return
	modulate = Color.WHITE
	if health <= 0:
		die()

func spawn_damage_number(amount: int):
	var label = Label.new()
	label.text = str(amount)
	label.position = global_position + Vector2(-15, -20)
	label.add_theme_font_size_override("font_size", 16)
	label.add_theme_color_override("font_color", Color(1, 1, 0.4))
	label.add_theme_color_override("font_outline_color", Color.BLACK)
	label.add_theme_constant_override("outline_size", 3)
	get_tree().current_scene.add_child(label)
	var tween = create_tween()
	tween.tween_property(label, "position", label.position + Vector2(0, -40), 0.5)
	tween.parallel().tween_property(label, "modulate:a", 0.0, 0.5)
	tween.tween_callback(label.queue_free)

func die():
	var score_val = 15 if not is_boss else 100
	GameManager.add_score(score_val)
	GameManager.register_kill()
	var memory_gain = 8.0 + GameManager.wave * 1.0
	if is_boss:
		memory_gain *= 3.0
	GameManager.add_memory(memory_gain)

	SoundFX.play("enemy_die", -4.0)

	if is_boss:
		Engine.time_scale = 0.15
		await get_tree().create_timer(0.1 * Engine.time_scale).timeout
		Engine.time_scale = lerpf(0.15, 1.0, 0.4)
		await get_tree().create_timer(0.2).timeout
		Engine.time_scale = 1.0
	else:
		Engine.time_scale = 0.3
		await get_tree().create_timer(0.05 * Engine.time_scale).timeout
		Engine.time_scale = 1.0

	var spark_count = 30 if is_boss else 12
	for i in range(spark_count):
		var spark = ColorRect.new()
		spark.size = Vector2(4, 4) if not is_boss else Vector2(6, 6)
		spark.global_position = global_position
		var c = sector_colors.get(enemy_type, Color(1, 0.15, 0.15))
		spark.color = c
		var angle = randf_range(0, TAU)
		var dist = randf_range(30, 120) if is_boss else randf_range(20, 80)
		get_tree().current_scene.add_child(spark)
		var tween = create_tween()
		tween.tween_property(spark, "global_position", global_position + Vector2(cos(angle), sin(angle)) * dist, 0.35)
		tween.parallel().tween_property(spark, "color:a", 0.0, 0.35)
		tween.tween_callback(spark.queue_free)

	if resource_pickup_scene:
		var pickup = resource_pickup_scene.instantiate()
		pickup.global_position = global_position
		var res_type = "organic"
		match enemy_type:
			"Hydro Core":
				res_type = "organic"
			"Reactor Gardens":
				res_type = "synthetic"
			"Cryo Labs":
				res_type = "data"
			"Observation Deck":
				var types = ["organic", "synthetic", "data"]
				res_type = types[randi() % 3]
		var drop_amt = randi_range(1, 2)
		if randf() < 0.2:
			drop_amt += 1
		get_tree().current_scene.call_deferred("add_child", pickup)
		pickup.call_deferred("initialize", res_type, drop_amt)

	queue_free()
