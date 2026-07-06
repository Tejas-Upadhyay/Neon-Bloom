extends CharacterBody2D

@export var speed := 400.0

var bullet_scene = preload("res://scenes/bullet/Bullet.tscn")
var shoot_timer := 0.0
var power_damage_timer := 0.0

var dash_speed := 1200.0
var dash_duration := 0.15
var dash_cooldown := 1.5
var dash_timer := 0.0
var dash_cooldown_timer := 0.0
var is_dashing := false
var dash_direction := Vector2.ZERO
var dash_invulnerable := false
var recoil_velocity := Vector2.ZERO

@onready var camera := $Camera2D
var shake_trauma := 0.0
var last_health := 100

func _ready():
	GameManager.health_changed.connect(_on_health_changed)
	GameManager.overdrive_state_changed.connect(_on_overdrive_state_changed)

	if not InputMap.has_action("dash"):
		InputMap.add_action("dash")
	if InputMap.action_get_events("dash").is_empty():
		var shift_ev = InputEventKey.new()
		shift_ev.physical_keycode = KEY_SHIFT
		InputMap.action_add_event("dash", shift_ev)
		var rmb_ev = InputEventMouseButton.new()
		rmb_ev.button_index = MOUSE_BUTTON_RIGHT
		InputMap.action_add_event("dash", rmb_ev)

	if InputMap.has_action("shoot"):
		var has_mouse = false
		for ev in InputMap.action_get_events("shoot"):
			if ev is InputEventMouseButton:
				has_mouse = true
				break
		if not has_mouse:
			var lmb = InputEventMouseButton.new()
			lmb.button_index = MOUSE_BUTTON_LEFT
			InputMap.action_add_event("shoot", lmb)

	queue_redraw()

func _draw():
	var mouse_dir = (get_global_mouse_position() - global_position).normalized()
	var angle = mouse_dir.angle()

	var is_overdrive = GameManager and GameManager.is_overdrive
	var body_color = Color(0.2, 1.0, 0.8) if not is_overdrive else Color(1.0, 0.4, 1.0)
	var glow_color = Color(0.1, 0.5, 0.4, 0.3) if not is_overdrive else Color(0.8, 0.2, 1.0, 0.3)

	if is_dashing:
		body_color = Color(0.0, 0.9, 1.0)
		glow_color = Color(0.0, 0.6, 1.0, 0.4)
		draw_circle(Vector2.ZERO, 24, Color(0.0, 0.9, 1.0, 0.15))
	elif dash_invulnerable:
		body_color = Color(0.8, 0.9, 1.0)

	draw_circle(Vector2.ZERO, 22, glow_color)
	var tip = Vector2(14, 0).rotated(angle)
	var left = Vector2(-8, 8).rotated(angle)
	var right = Vector2(-8, -8).rotated(angle)
	draw_circle(Vector2.ZERO, 10, Color(0.0, 0.0, 0.0, 0.5))
	var points = PackedVector2Array([tip, left, right])
	draw_colored_polygon(points, body_color)
	draw_circle(Vector2.ZERO, 4, Color(1, 1, 1, 0.8))
	if is_overdrive:
		draw_circle(Vector2.ZERO, 16, Color(1.0, 0.4, 1.0, 0.15 + sin(Time.get_ticks_msec() * 0.01) * 0.1))

func _physics_process(delta):
	if GameManager.is_game_over:
		velocity = Vector2.ZERO
		move_and_slide()
		return

	dash_cooldown_timer = max(dash_cooldown_timer - delta, 0.0)

	if is_dashing:
		dash_timer -= delta
		velocity = dash_direction * dash_speed
		move_and_slide()
		if dash_timer <= 0:
			is_dashing = false
			dash_invulnerable = false
			modulate.a = 1.0
	else:
		var direction = Input.get_vector("move_left", "move_right", "move_up", "move_down")
		var speed_mult = 1.0 + GameManager.upgrades.get("speed", 0) * 0.15
		if GameManager.is_overdrive:
			speed_mult *= 1.3
		if GameManager.player_power <= 0.0:
			speed_mult *= 0.5
		recoil_velocity = recoil_velocity.lerp(Vector2.ZERO, 8.0 * delta)
		velocity = direction * (speed * speed_mult) + recoil_velocity
		move_and_slide()
		if Input.is_action_just_pressed("dash") and dash_cooldown_timer <= 0:
			start_dash(direction)

	var mouse_dir = (get_global_mouse_position() - global_position).normalized()
	rotation = mouse_dir.angle()

	if camera:
		if shake_trauma > 0:
			shake_trauma = max(shake_trauma - delta * 1.5, 0.0)
			var amount = shake_trauma * shake_trauma
			camera.offset = Vector2(randf_range(-1, 1), randf_range(-1, 1)) * 12.0 * amount
		else:
			camera.offset = Vector2.ZERO

	var photo_lvl = GameManager.upgrades.get("photosynthesis", 0)
	var base_drain = 1.5 * (1.0 - photo_lvl * 0.18)
	var movement_drain = 0.5 if velocity.length() > 50 else 0.0
	GameManager.change_power(-(base_drain + movement_drain) * delta)

	if GameManager.player_power <= 0.0:
		power_damage_timer += delta
		if power_damage_timer >= 1.0:
			power_damage_timer = 0.0
			GameManager.damage_player(3)
			spawn_floating_text("-3 HP (No Power)", global_position, Color(1, 0.2, 0.2))

	shoot_timer -= delta
	if Input.is_action_pressed("shoot") and shoot_timer <= 0:
		shoot()
		var cd_lvl = GameManager.upgrades.get("cooldown", 0)
		var shoot_cooldown = 0.25 * (1.0 - cd_lvl * 0.12)
		if GameManager.is_overdrive:
			shoot_cooldown *= 0.5
		shoot_timer = shoot_cooldown

func start_dash(direction: Vector2):
	if direction == Vector2.ZERO:
		direction = (get_global_mouse_position() - global_position).normalized()
	dash_direction = direction.normalized()
	is_dashing = true
	dash_invulnerable = true
	dash_timer = dash_duration
	var dash_lvl = GameManager.upgrades.get("dash_energy", 0)
	var cd_reduction = dash_lvl * 0.2
	dash_cooldown_timer = max(0.5, dash_cooldown - cd_reduction)

	modulate.a = 0.4
	shake_trauma = min(shake_trauma + 0.2, 1.0)
	var power_cost = max(3.0, 8.0 - dash_lvl * 1.5)
	GameManager.change_power(-power_cost)
	SoundFX.play("dash", -8.0)
	spawn_floating_text("DASH!", global_position, Color(0.0, 0.9, 1.0))

func shoot():
	shake_trauma = min(shake_trauma + 0.08, 1.0)
	var mouse_pos = get_global_mouse_position()
	var dir = (mouse_pos - global_position).normalized()
	recoil_velocity += -dir * 80.0

	if GameManager.player_power <= 0.0:
		GameManager.damage_player(2)
		spawn_floating_text("-2 HP (Emergency Draw)", global_position, Color(1, 0.4, 0.2))
	else:
		GameManager.change_power(-1.5)

	SoundFX.play("shoot", -10.0)

	var has_split = GameManager.upgrades.get("split_shot", 0) > 0
	if has_split:
		spawn_bullet(dir)
		spawn_bullet(dir.rotated(deg_to_rad(15)))
		spawn_bullet(dir.rotated(deg_to_rad(-15)))
	else:
		spawn_bullet(dir)

func spawn_bullet(dir: Vector2):
	var bullet = bullet_scene.instantiate()
	bullet.global_position = global_position
	bullet.direction = dir
	bullet.rotation = dir.angle()
	if GameManager.is_overdrive:
		bullet.damage = int(bullet.damage * 2)
	get_tree().current_scene.add_child(bullet)

func spawn_floating_text(text: String, pos: Vector2, color: Color):
	var label = Label.new()
	label.text = text
	label.position = pos + Vector2(-50, -30)
	label.add_theme_font_size_override("font_size", 18)
	label.add_theme_color_override("font_color", color)
	label.add_theme_color_override("font_outline_color", Color.BLACK)
	label.add_theme_constant_override("outline_size", 4)
	get_tree().current_scene.add_child(label)
	var tween = create_tween()
	tween.tween_property(label, "position", label.position + Vector2(0, -70), 0.7)
	tween.parallel().tween_property(label, "modulate:a", 0.0, 0.7)
	tween.tween_callback(label.queue_free)

func _on_health_changed(new_health, max_health):
	if new_health < last_health:
		shake_trauma = min(shake_trauma + 0.5, 1.0)
		SoundFX.play("player_hurt", -6.0)
		var tween = create_tween()
		tween.tween_property(self, "modulate", Color(1, 0.3, 0.3), 0.08)
		tween.tween_property(self, "modulate", Color.WHITE, 0.1)
	last_health = new_health
	if new_health <= 0:
		modulate = Color(0.3, 0.1, 0.1)

func _on_overdrive_state_changed(is_overdrive: bool):
	if is_overdrive:
		spawn_floating_text("OVERDRIVE DETECTED!", global_position, Color(1, 0.3, 1))
	else:
		spawn_floating_text("Overdrive Ended", global_position, Color(0.6, 0.6, 0.8))
