extends CanvasLayer

@onready var score_label := $MarginContainer/VBoxContainer/ScoreLabel
@onready var wave_label := $MarginContainer/VBoxContainer/WaveLabel
@onready var health_bar := $MarginContainer/VBoxContainer/HealthBar
@onready var health_label := $MarginContainer/VBoxContainer/HealthLabel
@onready var game_over_panel := $GameOverPanel
@onready var final_score_label := $GameOverPanel/VBoxContainer/FinalScoreLabel
@onready var vbox := $MarginContainer/VBoxContainer
@onready var instructions_label := $Instructions

# Programmatic HUD references
var power_label: Label
var power_bar: ProgressBar
var memory_label: Label
var memory_bar: ProgressBar

var organic_label: Label
var synthetic_label: Label
var data_label: Label

# Style boxes to adjust color dynamically
var sb_power: StyleBoxFlat
var sb_memory: StyleBoxFlat

# Shop overlay references
var upgrade_panel: Panel
var upgrade_items_vbox: VBoxContainer
var upgrade_rows = {}

# Sector indicator
var sector_label: Label

# Kill counter & combo
var kills_label: Label
var combo_label: Label
var kill_count: int = 0
var combo_count: int = 0
var combo_timer: float = 0.0
var last_score: int = 0

# Running totals for game-over stats
var total_organic: int = 0
var total_synthetic: int = 0
var total_data: int = 0
var total_upgrades: int = 0

# Low-health warning overlay
var low_health_warning: ColorRect
var _current_health_ratio: float = 1.0

func _ready():
	# Make sure the UI runs even when the game is paused
	process_mode = Node.PROCESS_MODE_ALWAYS

	# Initial HUD text settings
	score_label.text = "Score: 0"
	wave_label.text = "Wave: 0"
	health_bar.max_value = GameManager.player_max_health
	health_bar.value = GameManager.player_max_health
	health_label.text = "HP: %d/%d" % [GameManager.player_max_health, GameManager.player_max_health]
	game_over_panel.hide()
	
	# Update instructions text to reflect mechanics
	if instructions_label:
		instructions_label.text = "WASD: Move | LMB: Shoot | RMB/Shift: Dash | [E]: Evolve Shop"

	# Build survival bars and resource HUD dynamically
	build_survival_hud()
	build_resources_hud()
	build_upgrade_shop()
	build_extra_hud()

	# Connect core game manager signals after building UI components
	GameManager.score_changed.connect(_on_score_changed)
	GameManager.wave_changed.connect(_on_wave_changed)
	GameManager.health_changed.connect(_on_health_changed)
	GameManager.game_over.connect(_on_game_over)
	
	# Connect new mechanic signals
	GameManager.resources_changed.connect(_on_resources_changed)
	GameManager.power_changed.connect(_on_power_changed)
	GameManager.memory_changed.connect(_on_memory_changed)
	GameManager.upgrade_purchased.connect(_on_upgrade_purchased)

	last_score = GameManager.score

func build_survival_hud():
	# 1. Power HUD Elements
	power_label = Label.new()
	power_label.text = "Power: 100%"
	power_label.add_theme_font_size_override("font_size", 22)
	power_label.add_theme_color_override("font_color", Color(1.0, 0.85, 0.2))
	power_label.add_theme_color_override("font_outline_color", Color.BLACK)
	power_label.add_theme_constant_override("outline_size", 3)
	vbox.add_child(power_label)
	
	power_bar = ProgressBar.new()
	power_bar.custom_minimum_size = Vector2(280, 16)
	power_bar.show_percentage = false
	power_bar.value = 100
	
	sb_power = StyleBoxFlat.new()
	sb_power.bg_color = Color(1.0, 0.8, 0.15)
	sb_power.corner_radius_top_left = 4
	sb_power.corner_radius_top_right = 4
	sb_power.corner_radius_bottom_right = 4
	sb_power.corner_radius_bottom_left = 4
	power_bar.add_theme_stylebox_override("fill", sb_power)
	vbox.add_child(power_bar)

	# 2. Memory HUD Elements
	memory_label = Label.new()
	memory_label.text = "Memory: 0%"
	memory_label.add_theme_font_size_override("font_size", 22)
	memory_label.add_theme_color_override("font_color", Color(0.8, 0.3, 1.0))
	memory_label.add_theme_color_override("font_outline_color", Color.BLACK)
	memory_label.add_theme_constant_override("outline_size", 3)
	vbox.add_child(memory_label)
	
	memory_bar = ProgressBar.new()
	memory_bar.custom_minimum_size = Vector2(280, 16)
	memory_bar.show_percentage = false
	memory_bar.value = 0
	
	sb_memory = StyleBoxFlat.new()
	sb_memory.bg_color = Color(0.7, 0.2, 0.9)
	sb_memory.corner_radius_top_left = 4
	sb_memory.corner_radius_top_right = 4
	sb_memory.corner_radius_bottom_right = 4
	sb_memory.corner_radius_bottom_left = 4
	memory_bar.add_theme_stylebox_override("fill", sb_memory)
	vbox.add_child(memory_bar)

func build_extra_hud():
	# --- Kills label (left HUD, below wave) ---
	kills_label = Label.new()
	kills_label.text = "Enemies Killed: 0"
	kills_label.add_theme_font_size_override("font_size", 20)
	kills_label.add_theme_color_override("font_color", Color(1.0, 0.45, 0.3))
	kills_label.add_theme_color_override("font_outline_color", Color.BLACK)
	kills_label.add_theme_constant_override("outline_size", 3)
	vbox.add_child(kills_label)

	# --- Combo label (left HUD, below kills) ---
	combo_label = Label.new()
	combo_label.text = ""
	combo_label.add_theme_font_size_override("font_size", 26)
	combo_label.add_theme_color_override("font_color", Color(1.0, 1.0, 0.2))
	combo_label.add_theme_color_override("font_outline_color", Color.BLACK)
	combo_label.add_theme_constant_override("outline_size", 4)
	vbox.add_child(combo_label)

	# --- Sector label (bottom-center) ---
	sector_label = Label.new()
	sector_label.text = ""
	sector_label.add_theme_font_size_override("font_size", 22)
	sector_label.add_theme_color_override("font_outline_color", Color.BLACK)
	sector_label.add_theme_constant_override("outline_size", 4)
	sector_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	sector_label.anchor_left = 0.0
	sector_label.anchor_right = 1.0
	sector_label.anchor_top = 1.0
	sector_label.anchor_bottom = 1.0
	sector_label.offset_top = -50
	sector_label.offset_bottom = -10
	add_child(sector_label)

	# --- Low-health warning vignette ---
	low_health_warning = ColorRect.new()
	low_health_warning.anchor_right = 1.0
	low_health_warning.anchor_bottom = 1.0
	low_health_warning.mouse_filter = Control.MOUSE_FILTER_IGNORE
	low_health_warning.color = Color(0.8, 0.0, 0.0, 0.0)
	add_child(low_health_warning)

func build_resources_hud():
	var res_container = MarginContainer.new()
	res_container.anchor_left = 1.0
	res_container.anchor_right = 1.0
	res_container.grow_horizontal = Control.GROW_DIRECTION_BEGIN
	res_container.offset_left = -300
	res_container.offset_right = -20
	res_container.offset_top = 20
	res_container.offset_bottom = 200
	add_child(res_container)
	
	var res_vbox = VBoxContainer.new()
	res_vbox.add_theme_constant_override("separation", 6)
	res_container.add_child(res_vbox)
	
	organic_label = Label.new()
	organic_label.text = "Organic: 0"
	organic_label.add_theme_font_size_override("font_size", 22)
	organic_label.add_theme_color_override("font_color", Color(0.2, 1.0, 0.4))
	organic_label.add_theme_color_override("font_outline_color", Color.BLACK)
	organic_label.add_theme_constant_override("outline_size", 3)
	organic_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	res_vbox.add_child(organic_label)
	
	synthetic_label = Label.new()
	synthetic_label.text = "Synthetic: 0"
	synthetic_label.add_theme_font_size_override("font_size", 22)
	synthetic_label.add_theme_color_override("font_color", Color(0.2, 0.6, 1.0))
	synthetic_label.add_theme_color_override("font_outline_color", Color.BLACK)
	synthetic_label.add_theme_constant_override("outline_size", 3)
	synthetic_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	res_vbox.add_child(synthetic_label)
	
	data_label = Label.new()
	data_label.text = "Data: 0"
	data_label.add_theme_font_size_override("font_size", 22)
	data_label.add_theme_color_override("font_color", Color(0.8, 0.2, 1.0))
	data_label.add_theme_color_override("font_outline_color", Color.BLACK)
	data_label.add_theme_constant_override("outline_size", 3)
	data_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	res_vbox.add_child(data_label)

func build_upgrade_shop():
	# Main panel overlay centered
	upgrade_panel = Panel.new()
	upgrade_panel.process_mode = Node.PROCESS_MODE_ALWAYS
	upgrade_panel.anchor_left = 0.5
	upgrade_panel.anchor_top = 0.5
	upgrade_panel.anchor_right = 0.5
	upgrade_panel.anchor_bottom = 0.5
	upgrade_panel.offset_left = -340
	upgrade_panel.offset_top = -280
	upgrade_panel.offset_right = 340
	upgrade_panel.offset_bottom = 280
	
	var shop_style = StyleBoxFlat.new()
	shop_style.bg_color = Color(0.04, 0.04, 0.07, 0.92)
	shop_style.border_width_left = 2
	shop_style.border_width_top = 2
	shop_style.border_width_right = 2
	shop_style.border_width_bottom = 2
	shop_style.border_color = Color(0.0, 0.8, 1.0, 0.4)
	shop_style.corner_radius_top_left = 12
	shop_style.corner_radius_top_right = 12
	shop_style.corner_radius_bottom_right = 12
	shop_style.corner_radius_bottom_left = 12
	upgrade_panel.add_theme_stylebox_override("panel", shop_style)
	
	add_child(upgrade_panel)
	upgrade_panel.hide()
	
	var shop_margin = MarginContainer.new()
	shop_margin.anchors_preset = Control.PRESET_FULL_RECT
	shop_margin.offset_left = 15
	shop_margin.offset_top = 15
	shop_margin.offset_right = -15
	shop_margin.offset_bottom = -15
	upgrade_panel.add_child(shop_margin)
	
	var shop_vbox = VBoxContainer.new()
	shop_vbox.add_theme_constant_override("separation", 10)
	shop_margin.add_child(shop_vbox)
	
	var shop_title = Label.new()
	shop_title.text = "CHASSIS EVOLUTION CHAMBER"
	shop_title.add_theme_font_size_override("font_size", 24)
	shop_title.add_theme_color_override("font_color", Color(0.0, 1.0, 0.8))
	shop_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	shop_vbox.add_child(shop_title)
	
	var shop_sub = Label.new()
	shop_sub.text = "Press [E] to return  |  Integrate plant genes to evolve"
	shop_sub.add_theme_font_size_override("font_size", 13)
	shop_sub.add_theme_color_override("font_color", Color(0.6, 0.6, 0.7))
	shop_sub.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	shop_vbox.add_child(shop_sub)
	
	var list_scroll = ScrollContainer.new()
	list_scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	shop_vbox.add_child(list_scroll)
	
	upgrade_items_vbox = VBoxContainer.new()
	upgrade_items_vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	upgrade_items_vbox.add_theme_constant_override("separation", 8)
	list_scroll.add_child(upgrade_items_vbox)
	
	build_upgrade_rows()

func build_upgrade_rows():
	var upgrades_list = ["speed", "health", "cooldown", "split_shot", "photosynthesis", "dash_energy"]
	
	for upgrade_name in upgrades_list:
		var row = PanelContainer.new()
		var row_style = StyleBoxFlat.new()
		row_style.bg_color = Color(0.08, 0.08, 0.12, 0.6)
		row_style.corner_radius_top_left = 6
		row_style.corner_radius_top_right = 6
		row_style.corner_radius_bottom_right = 6
		row_style.corner_radius_bottom_left = 6
		row.add_theme_stylebox_override("panel", row_style)
		
		upgrade_items_vbox.add_child(row)
		
		var margin = MarginContainer.new()
		margin.offset_left = 10
		margin.offset_right = -10
		margin.offset_top = 6
		margin.offset_bottom = -6
		row.add_child(margin)
		
		var hbox = HBoxContainer.new()
		hbox.add_theme_constant_override("separation", 15)
		margin.add_child(hbox)
		
		var info_vbox = VBoxContainer.new()
		info_vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		hbox.add_child(info_vbox)
		
		var title_lbl = Label.new()
		title_lbl.add_theme_font_size_override("font_size", 16)
		title_lbl.add_theme_color_override("font_color", Color(1, 1, 1))
		info_vbox.add_child(title_lbl)
		
		var desc_lbl = Label.new()
		desc_lbl.add_theme_font_size_override("font_size", 11)
		desc_lbl.add_theme_color_override("font_color", Color(0.6, 0.6, 0.7))
		info_vbox.add_child(desc_lbl)
		
		var cost_lbl = Label.new()
		cost_lbl.add_theme_font_size_override("font_size", 13)
		cost_lbl.add_theme_color_override("font_color", Color(1.0, 0.9, 0.4))
		cost_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
		cost_lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		hbox.add_child(cost_lbl)
		
		var buy_btn = Button.new()
		buy_btn.custom_minimum_size = Vector2(100, 32)
		buy_btn.text = "EVOLVE"
		buy_btn.pressed.connect(func(): _on_buy_pressed(upgrade_name))
		hbox.add_child(buy_btn)
		
		upgrade_rows[upgrade_name] = {
			"title": title_lbl,
			"desc": desc_lbl,
			"cost": cost_lbl,
			"button": buy_btn
		}

func _on_buy_pressed(upgrade_name: String):
	if GameManager.purchase_upgrade(upgrade_name):
		SoundFX.play("upgrade", -6.0)
		update_upgrade_ui()
		var player = get_tree().get_first_node_in_group("player")
		if player:
			player.spawn_floating_text("Evolved: " + upgrade_name.capitalize(), player.global_position, Color(0, 1, 0.8))

func update_upgrade_ui():
	var upgrades_desc = {
		"speed": "Improves motor functions (speed +15% per level)",
		"health": "Adds heavy metal plating (max HP +20, heals and reduces damage)",
		"cooldown": "Overclocks CPU calculations (fire rate +12% per level)",
		"split_shot": "Installs multi-emitter core (fires 3-bullet spread)",
		"photosynthesis": "Optimizes solar absorbency (reduces Power drain by 18%)",
		"dash_energy": "Phase-shift coolant (dash cooldown -0.2s, power cost -1.5 per level)"
	}
	
	var upgrades_titles = {
		"speed": "Speed Chassis",
		"health": "Reinforced Frame",
		"cooldown": "Overclock Processor",
		"split_shot": "Split-shot Emitter",
		"photosynthesis": "Photosynthesis Core",
		"dash_energy": "Phase-Shift Module"
	}
	
	for upgrade_name in upgrade_rows:
		var row = upgrade_rows[upgrade_name]
		var lvl = GameManager.upgrades[upgrade_name]
		var max_lvl = GameManager.max_upgrades[upgrade_name]
		
		row["title"].text = "%s (Lvl %d/%d)" % [upgrades_titles[upgrade_name], lvl, max_lvl]
		row["desc"].text = upgrades_desc[upgrade_name]
		
		if lvl >= max_lvl:
			row["cost"].text = "FULLY EVOLVED"
			row["cost"].add_theme_color_override("font_color", Color(0.2, 1.0, 0.4))
			row["button"].text = "MAXED"
			row["button"].disabled = true
		else:
			var cost = GameManager.get_upgrade_cost(upgrade_name)
			var cost_str = ""
			var can_afford = true
			
			for res_type in cost:
				var amt = cost[res_type]
				cost_str += "%d %s\n" % [amt, res_type.capitalize()]
				
				if res_type == "organic" and GameManager.organic < amt:
					can_afford = false
				elif res_type == "synthetic" and GameManager.synthetic < amt:
					can_afford = false
				elif res_type == "data" and GameManager.data < amt:
					can_afford = false
					
			row["cost"].text = cost_str.strip_edges()
			
			if can_afford:
				row["cost"].add_theme_color_override("font_color", Color(1.0, 0.9, 0.4))
				row["button"].disabled = false
				row["button"].text = "EVOLVE"
			else:
				row["cost"].add_theme_color_override("font_color", Color(0.8, 0.3, 0.3))
				row["button"].disabled = true
				row["button"].text = "INSUFFICIENT"

func _unhandled_input(event):
	if event is InputEventKey and event.keycode == KEY_E and event.pressed and not event.is_echo():
		if GameManager.is_game_over:
			return
		toggle_upgrade_shop()

func toggle_upgrade_shop():
	var new_state = not upgrade_panel.visible
	upgrade_panel.visible = new_state
	get_tree().paused = new_state
	
	if new_state:
		update_upgrade_ui()

func _process(delta):
	# --- Sector indicator ---
	var player = get_tree().get_first_node_in_group("player")
	if player and sector_label:
		var px = player.global_position.x
		var py = player.global_position.y
		var sector_name := ""
		var sector_color := Color.WHITE
		if px < 3000 and py < 3000:
			sector_name = "Hydro Core"
			sector_color = Color(0.2, 1.0, 0.4)
		elif px >= 3000 and py < 3000:
			sector_name = "Reactor Gardens"
			sector_color = Color(0.2, 0.6, 1.0)
		elif px < 3000 and py >= 3000:
			sector_name = "Cryo Labs"
			sector_color = Color(0.8, 0.2, 1.0)
		else:
			sector_name = "Observation Deck"
			sector_color = Color(1.0, 0.15, 0.15)
		sector_label.text = "[ " + sector_name + " ]"
		sector_label.add_theme_color_override("font_color", sector_color)

	# --- Low-health pulsing + vignette ---
	if health_bar and low_health_warning:
		if _current_health_ratio < 0.25 and _current_health_ratio > 0.0:
			# Pulse health bar between red and dark red
			var pulse = (sin(Time.get_ticks_msec() * 0.008) + 1.0) * 0.5  # 0..1
			var bar_color = Color(1.0, 0.1 + pulse * 0.15, 0.1 + pulse * 0.15)
			var bar_sb = health_bar.get_theme_stylebox("fill")
			if bar_sb is StyleBoxFlat:
				bar_sb.bg_color = bar_color
			# Vignette fade in/out
			var vignette_alpha = 0.08 + pulse * 0.12
			low_health_warning.color = Color(0.8, 0.0, 0.0, vignette_alpha)
		else:
			low_health_warning.color = Color(0.8, 0.0, 0.0, 0.0)

	# --- Combo timer countdown ---
	if combo_timer > 0.0:
		combo_timer -= delta
		if combo_timer <= 0.0:
			combo_count = 0
			if combo_label:
				combo_label.text = ""

func _on_score_changed(new_score):
	if score_label:
		score_label.text = "Score: " + str(new_score)

	# Detect kills by score increase of 15
	var score_diff = new_score - last_score
	last_score = new_score
	if score_diff > 0 and score_diff % 15 == 0:
		var new_kills = score_diff / 15
		kill_count += new_kills
		if kills_label:
			kills_label.text = "Enemies Killed: " + str(kill_count)
		# Update combo
		for i in new_kills:
			combo_count += 1
			combo_timer = 3.0
		if combo_count > 1 and combo_label:
			combo_label.text = "COMBO x%d!" % combo_count

func _on_wave_changed(new_wave):
	if wave_label:
		wave_label.text = "Wave: " + str(new_wave)

func _on_health_changed(new_health, max_health):
	if health_bar:
		health_bar.max_value = max_health
		health_bar.value = new_health
	if health_label:
		health_label.text = "HP: %d/%d" % [new_health, max_health]
	_current_health_ratio = float(new_health) / float(max_health) if max_health > 0 else 0.0

func _on_resources_changed(organic, synthetic, data):
	if not organic_label or not synthetic_label or not data_label:
		return
	# Track running totals (resources only go up via collection, down via purchases)
	if organic > GameManager.organic:
		total_organic += organic - GameManager.organic
	if synthetic > GameManager.synthetic:
		total_synthetic += synthetic - GameManager.synthetic
	if data > GameManager.data:
		total_data += data - GameManager.data
	organic_label.text = "Organic: " + str(organic)
	synthetic_label.text = "Synthetic: " + str(synthetic)
	data_label.text = "Data: " + str(data)
	if upgrade_panel and upgrade_panel.visible:
		update_upgrade_ui()

func _on_power_changed(power, max_power):
	if not power_bar or not power_label:
		return
	power_bar.max_value = max_power
	power_bar.value = power
	power_label.text = "Power: %d%%" % [int(power)]
	if sb_power:
		if power < 25.0:
			sb_power.bg_color = Color(1.0, 0.25, 0.25)
		else:
			sb_power.bg_color = Color(1.0, 0.8, 0.15)

func _on_memory_changed(memory, max_memory):
	if not memory_bar or not memory_label:
		return
	memory_bar.max_value = max_memory
	memory_bar.value = memory
	memory_label.text = "Memory: %d%%" % [int(memory)]
	if sb_memory:
		if GameManager.is_overdrive:
			sb_memory.bg_color = Color(1.0, 0.4, 1.0)
			memory_label.text = "OVERDRIVE ACTIVE!"
		else:
			sb_memory.bg_color = Color(0.7, 0.2, 0.9)

func _on_upgrade_purchased(upgrade_name, level):
	total_upgrades += 1
	if upgrade_panel and upgrade_panel.visible:
		update_upgrade_ui()

func _on_game_over():
	if upgrade_panel and upgrade_panel.visible:
		toggle_upgrade_shop()
	if game_over_panel:
		game_over_panel.show()
	if final_score_label:
		var stats_text = "Final Score: %d\n" % GameManager.score
		stats_text += "Waves Survived: %d\n" % GameManager.wave
		stats_text += "Enemies Killed: %d\n" % kill_count
		stats_text += "\nResources Collected:\n"
		stats_text += "  Organic: %d\n" % total_organic
		stats_text += "  Synthetic: %d\n" % total_synthetic
		stats_text += "  Data: %d\n" % total_data
		stats_text += "\nUpgrades Purchased: %d" % total_upgrades
		final_score_label.text = stats_text
