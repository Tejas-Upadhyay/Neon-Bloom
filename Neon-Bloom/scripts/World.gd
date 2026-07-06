extends Node2D

const WorldGenerator = preload("res://scripts/WorldGenerator.gd")

var plant_scene = preload("res://scenes/plant/Plant.tscn")
var enemy_scene = preload("res://scenes/enemy/Enemy.tscn")

var enemies_per_wave := 3
var spawn_radius := 1000.0
var wave_delay := 3.0
var plant_spawn_timer := 0.0
var plant_spawn_interval := 4.0
var max_plants := 30

var world_size := 6000.0

# --- Spawn queue for staggered spawning ---
var spawn_queue: Array = []
var spawn_queue_timer := 0.0
const SPAWN_QUEUE_INTERVAL := 0.3

# --- Wave tracking ---
var wave_cleared := false  # True when all enemies dead and bonus not yet given
var is_boss_wave := false

@onready var player := $Player

# --- Minimap ---
var minimap_layer: CanvasLayer
var minimap_node: Node2D

func _ready():
	randomize()

	# Integrate WorldGenerator to setup procedural visual layout
	var generator = WorldGenerator.new()
	generator.generate_floor(self, $Background.texture)
	generator.generate_decorations(self)
	$Background.hide()

	MusicPlayer.play_music("ambient", 1.5)

	# Spawn player in the center (juncture of all sectors)
	player.global_position = Vector2(3000, 3000)

	# Constrain camera to the 6000x6000px space station boundaries
	var camera = player.get_node("Camera2D")
	if camera:
		camera.limit_left = 0
		camera.limit_top = 0
		camera.limit_right = 6000
		camera.limit_bottom = 6000

	spawn_initial_plants()
	_setup_minimap()
	start_next_wave()

func _process(delta):
	if GameManager.is_game_over:
		return

	if get_tree().paused:
		return

	# --- World boundary enforcement ---
	player.global_position.x = clamp(player.global_position.x, 0, world_size)
	player.global_position.y = clamp(player.global_position.y, 0, world_size)

	# --- Plant spawning ---
	plant_spawn_timer += delta
	if plant_spawn_timer >= plant_spawn_interval:
		plant_spawn_timer = 0
		try_spawn_plant_random()

	# --- Staggered spawn queue ---
	if spawn_queue.size() > 0:
		spawn_queue_timer += delta
		if spawn_queue_timer >= SPAWN_QUEUE_INTERVAL:
			spawn_queue_timer = 0.0
			var entry = spawn_queue.pop_front()
			_do_spawn_enemy(entry.pos, entry.get("is_boss", false))

	# --- Wave cleared detection ---
	var enemy_count = get_tree().get_nodes_in_group("enemy").size()
	if enemy_count == 0 and spawn_queue.size() == 0:
		if not wave_cleared and GameManager.wave > 0:
			wave_cleared = true
			_give_wave_bonus()
			wave_delay = 4.0 + GameManager.wave * 0.5
		wave_delay -= delta
		if wave_delay <= 0:
			start_next_wave()

	# --- Update minimap ---
	if minimap_node:
		minimap_node.queue_redraw()

# ============================================================
#  SECTOR HELPER
# ============================================================

func get_sector_at(pos: Vector2) -> String:
	if pos.x < 3000:
		if pos.y < 3000:
			return "Hydro Core"
		else:
			return "Cryo Labs"
	else:
		if pos.y < 3000:
			return "Reactor Gardens"
		else:
			return "Observation Deck"

# ============================================================
#  PLANT SPAWNING
# ============================================================

func spawn_initial_plants():
	for i in range(15):
		var pos = Vector2(
			randf_range(200, world_size - 200),
			randf_range(200, world_size - 200)
		)
		spawn_plant(pos)

func try_spawn_plant_random():
	var plants = get_tree().get_nodes_in_group("plant")
	if plants.size() >= max_plants:
		return
	var pos = Vector2(
		randf_range(200, world_size - 200),
		randf_range(200, world_size - 200)
	)
	spawn_plant(pos)

func spawn_plant(pos: Vector2):
	if not plant_scene:
		return
	var plant = plant_scene.instantiate()
	plant.position = pos

	# Determine plant type based on the sector it spawns in
	var sector = get_sector_at(pos)
	match sector:
		"Hydro Core":
			plant.plant_type = "organic"
		"Reactor Gardens":
			plant.plant_type = "synthetic"
		"Cryo Labs":
			plant.plant_type = "data"
		"Observation Deck":
			var types = ["organic", "synthetic", "data"]
			plant.plant_type = types[randi() % 3]

	add_child(plant)

# ============================================================
#  WAVE SYSTEM
# ============================================================

func start_next_wave():
	GameManager.next_wave()
	wave_cleared = false

	is_boss_wave = (GameManager.wave % 5 == 0)
	if is_boss_wave:
		MusicPlayer.play_music("boss", 1.0)
	elif GameManager.wave >= 3:
		MusicPlayer.play_music("tense", 1.5)
	else:
		MusicPlayer.play_music("ambient", 1.5)

	# --- Wave announcement ---
	_show_wave_announcement()
	SoundFX.play("wave_start", -6.0)

	# Scale enemy count
	var count = enemies_per_wave + (GameManager.wave * 2)

	if is_boss_wave:
		# Boss wave: spawn the boss + half the normal regular enemies
		var regular_count = int(count / 2.0)
		# Queue regular enemies
		for i in range(regular_count):
			var pos = _random_spawn_pos()
			spawn_queue.append({"pos": pos, "is_boss": false})
		# Queue the boss
		var boss_pos = _random_spawn_pos()
		spawn_queue.append({"pos": boss_pos, "is_boss": true})
	else:
		for i in range(count):
			var pos = _random_spawn_pos()
			spawn_queue.append({"pos": pos, "is_boss": false})

func _random_spawn_pos() -> Vector2:
	var angle = randf_range(0, TAU)
	var dist = randf_range(450, spawn_radius)
	var pos = player.global_position + Vector2(cos(angle), sin(angle)) * dist
	pos.x = clamp(pos.x, 50, world_size - 50)
	pos.y = clamp(pos.y, 50, world_size - 50)
	return pos

# ============================================================
#  ENEMY SPAWNING (called from queue)
# ============================================================

func _do_spawn_enemy(pos: Vector2, boss: bool):
	if boss:
		_spawn_boss(pos)
	else:
		spawn_enemy(pos)

func spawn_enemy(pos: Vector2):
	if not enemy_scene:
		return
	var enemy = enemy_scene.instantiate()
	enemy.position = pos

	# Sector-based scaling
	var sector = get_sector_at(pos)
	var scale_factor = 1.0 + GameManager.wave * 0.05
	var base_hp := int(50 * scale_factor)
	var base_dmg := 10 + GameManager.wave * 2
	var base_speed := 200.0 + GameManager.wave * 5

	enemy.enemy_type = sector

	match sector:
		"Hydro Core": # Fast, weaker enemies
			enemy.health = int(base_hp * 0.8)
			enemy.damage = int(base_dmg * 0.9)
			enemy.speed = base_speed * 1.25
		"Reactor Gardens": # Normal speed, high damage
			enemy.health = base_hp
			enemy.damage = int(base_dmg * 1.4)
			enemy.speed = base_speed
		"Cryo Labs": # Slow, tanky enemies
			enemy.health = int(base_hp * 1.6)
			enemy.damage = base_dmg
			enemy.speed = base_speed * 0.75
		"Observation Deck": # Strong hybrid enemies
			enemy.health = int(base_hp * 1.2)
			enemy.damage = int(base_dmg * 1.2)
			enemy.speed = base_speed * 1.1

	add_child(enemy)

func _spawn_boss(pos: Vector2):
	if not enemy_scene:
		return
	var enemy = enemy_scene.instantiate()
	enemy.position = pos

	var sector = get_sector_at(pos)
	var scale_factor = 1.0 + GameManager.wave * 0.05
	var base_hp := int(50 * scale_factor)
	var base_dmg := 10 + GameManager.wave * 2
	var base_speed := 200.0 + GameManager.wave * 5

	# Boss stats: 5x HP, 2x damage, 0.6x speed
	enemy.health = int(base_hp * 5.0)
	enemy.damage = int(base_dmg * 2.0)
	enemy.speed = base_speed * 0.6

	enemy.is_boss = true
	enemy.enemy_type = sector

	# Boss visual: large scale
	enemy.scale = Vector2(0.15, 0.15)

	add_child(enemy)

# ============================================================
#  BETWEEN-WAVE BONUS
# ============================================================

func _give_wave_bonus():
	GameManager.heal_player(10)
	GameManager.change_power(15.0)
	# Show floating text on the player
	if player.has_method("spawn_floating_text"):
		player.spawn_floating_text("+10 HP  +15 Power", player.global_position, Color(0.3, 1.0, 0.5))

# ============================================================
#  WAVE ANNOUNCEMENT
# ============================================================

func _show_wave_announcement():
	var announcement_layer = CanvasLayer.new()
	announcement_layer.layer = 20
	add_child(announcement_layer)

	var label = Label.new()
	if is_boss_wave:
		label.text = "BOSS WAVE!"
	else:
		label.text = "WAVE " + str(GameManager.wave)

	label.add_theme_font_size_override("font_size", 72)
	label.add_theme_color_override("font_color", Color(1, 0.9, 0.2) if is_boss_wave else Color(1, 1, 1))
	label.add_theme_color_override("font_outline_color", Color.BLACK)
	label.add_theme_constant_override("outline_size", 6)
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.anchors_preset = Control.PRESET_CENTER
	label.grow_horizontal = Control.GROW_DIRECTION_BOTH
	label.grow_vertical = Control.GROW_DIRECTION_BOTH
	label.pivot_offset = label.size / 2.0

	announcement_layer.add_child(label)

	# Wait a frame so the label sizes itself, then fix pivot
	await get_tree().process_frame
	label.pivot_offset = label.size / 2.0

	# Tween: scale up and fade out over 1.5 seconds
	label.scale = Vector2(0.5, 0.5)
	label.modulate.a = 1.0
	var tween = create_tween()
	tween.set_parallel(true)
	tween.tween_property(label, "scale", Vector2(1.5, 1.5), 1.5).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_CUBIC)
	tween.tween_property(label, "modulate:a", 0.0, 1.5).set_ease(Tween.EASE_IN).set_trans(Tween.TRANS_CUBIC)
	tween.set_parallel(false)
	tween.tween_callback(announcement_layer.queue_free)

# ============================================================
#  MINIMAP
# ============================================================

func _setup_minimap():
	minimap_layer = CanvasLayer.new()
	minimap_layer.layer = 10
	add_child(minimap_layer)

	minimap_node = _MinimapDrawer.new()
	minimap_node.world_ref = self
	minimap_layer.add_child(minimap_node)

# Inner class for minimap drawing
class _MinimapDrawer extends Node2D:
	const MAP_SIZE := 150.0
	const MAP_MARGIN := 10.0
	var world_ref: Node2D

	func _draw():
		if not world_ref:
			return

		# Position the minimap in the bottom-right corner of the screen
		var viewport_size = get_viewport().get_visible_rect().size
		var map_origin = Vector2(
			viewport_size.x - MAP_SIZE - MAP_MARGIN,
			viewport_size.y - MAP_SIZE - MAP_MARGIN
		)

		# Background
		draw_rect(Rect2(map_origin, Vector2(MAP_SIZE, MAP_SIZE)), Color(0.05, 0.05, 0.1, 0.75))
		# Border
		draw_rect(Rect2(map_origin, Vector2(MAP_SIZE, MAP_SIZE)), Color(0.4, 0.4, 0.6, 0.8), false, 1.5)

		var ws = world_ref.world_size

		# --- Helper: world pos → minimap pos ---
		# We capture map_origin and ws for the lambda
		var to_map = func(world_pos: Vector2) -> Vector2:
			return map_origin + Vector2(
				clamp(world_pos.x / ws, 0.0, 1.0) * MAP_SIZE,
				clamp(world_pos.y / ws, 0.0, 1.0) * MAP_SIZE
			)

		# Plants (blue dots)
		for p in world_ref.get_tree().get_nodes_in_group("plant"):
			var mp = to_map.call(p.global_position)
			draw_circle(mp, 1.5, Color(0.3, 0.5, 1.0, 0.9))

		# Resource pickups (yellow dots)
		for r in world_ref.get_tree().get_nodes_in_group("resource"):
			var mp = to_map.call(r.global_position)
			draw_circle(mp, 2.0, Color(1.0, 0.9, 0.2, 0.9))

		# Enemies (red dots)
		for e in world_ref.get_tree().get_nodes_in_group("enemy"):
			var mp = to_map.call(e.global_position)
			draw_circle(mp, 2.5, Color(1.0, 0.2, 0.2, 0.9))

		# Player (green dot)
		if world_ref.player:
			var pp = to_map.call(world_ref.player.global_position)
			draw_circle(pp, 3.5, Color(0.2, 1.0, 0.4, 1.0))

		# Camera viewport bounds (white outline)
		var cam = world_ref.player.get_node_or_null("Camera2D") if world_ref.player else null
		if cam:
			var vp_size = world_ref.get_viewport().get_visible_rect().size
			var zoom = cam.zoom
			# Actual visible area in world coords
			var half_view = vp_size / (2.0 * zoom)
			var cam_center = world_ref.player.global_position + cam.offset
			var tl = to_map.call(cam_center - half_view)
			var br = to_map.call(cam_center + half_view)
			var rect = Rect2(tl, br - tl)
			draw_rect(rect, Color(1.0, 1.0, 1.0, 0.6), false, 1.0)

# ============================================================
#  INPUT / RESTART
# ============================================================

func _unhandled_input(event):
	if event is InputEventKey and event.keycode == KEY_ESCAPE and event.pressed:
		if not GameManager.is_game_over:
			_pause_game()
		return
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		if GameManager.is_game_over:
			call_deferred("_restart_game")

func _pause_game():
	if get_tree().paused:
		return
	get_tree().paused = true
	var pm = load("res://scenes/menu/PauseMenu.tscn").instantiate()
	add_child(pm)

func _restart_game():
	get_tree().reload_current_scene()
	GameManager.restart()
