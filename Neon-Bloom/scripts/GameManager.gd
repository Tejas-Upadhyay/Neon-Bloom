extends Node

signal score_changed(new_score)
signal wave_changed(new_wave)
signal health_changed(new_health, max_health)
signal game_over

const SAVE_PATH = "user://neon_bloom_save.json"

# Extended mechanics signals
signal resources_changed(organic: int, synthetic: int, data: int)
signal power_changed(power: float, max_power: float)
signal memory_changed(memory: float, max_memory: float)
signal overdrive_state_changed(is_overdrive: bool)
signal upgrade_purchased(upgrade_name: String, level: int)
signal enemy_killed(kill_count: int)

var score := 0
var wave := 0
var player_health := 100
var player_max_health := 100
var is_game_over := false
var kill_count := 0

# Extended player stats
var organic := 0
var synthetic := 0
var data := 0

var player_power := 100.0
var player_max_power := 100.0
var player_memory := 0.0
var player_max_memory := 100.0
var is_overdrive := false
var overdrive_timer := 0.0
var overdrive_duration := 10.0

# Upgrades
var upgrades = {
	"speed": 0,
	"health": 0,
	"cooldown": 0,
	"split_shot": 0,
	"photosynthesis": 0,
	"dash_energy": 0
}

var max_upgrades = {
	"speed": 5,
	"health": 5,
	"cooldown": 5,
	"split_shot": 1,
	"photosynthesis": 4,
	"dash_energy": 3
}

func _ready():
	setup_inputs()
	load_game()
	load_global_settings()

func setup_inputs():
	var actions = {
		"move_left": [KEY_A, KEY_LEFT],
		"move_right": [KEY_D, KEY_RIGHT],
		"move_up": [KEY_W, KEY_UP],
		"move_down": [KEY_S, KEY_DOWN],
		"shoot": [KEY_SPACE, KEY_ENTER]
	}
	
	for action in actions:
		if not InputMap.has_action(action):
			InputMap.add_action(action)
		
		# Only populate if action currently has no events to avoid duplication
		if InputMap.action_get_events(action).is_empty():
			for key_code in actions[action]:
				var ev = InputEventKey.new()
				ev.physical_keycode = key_code
				InputMap.action_add_event(action, ev)

func _process(delta: float):
	if is_game_over:
		return
		
	# Overdrive timer countdown
	if is_overdrive:
		overdrive_timer -= delta
		player_memory = (overdrive_timer / overdrive_duration) * player_max_memory
		memory_changed.emit(player_memory, player_max_memory)
		if overdrive_timer <= 0:
			is_overdrive = false
			player_memory = 0.0
			overdrive_state_changed.emit(false)
			memory_changed.emit(0.0, player_max_memory)

func add_score(amount: int):
	score += amount
	score_changed.emit(score)

func register_kill():
	kill_count += 1
	enemy_killed.emit(kill_count)

func next_wave():
	wave += 1
	wave_changed.emit(wave)

func damage_player(amount: int):
	if is_game_over:
		return
	# Check if player is dash-invulnerable
	var player = get_tree().get_first_node_in_group("player") if get_tree() else null
	if player and player.get("dash_invulnerable") == true:
		return
	player_health = max(0, player_health - amount)
	health_changed.emit(player_health, player_max_health)
	if player_health <= 0:
		is_game_over = true
		game_over.emit()
		MusicPlayer.play_music("menu", 1.0)
		Engine.time_scale = 0.25
		_restore_time_scale()
		SoundFX.play("game_over", -3.0)

func heal_player(amount: int):
	player_health = min(player_max_health, player_health + amount)
	health_changed.emit(player_health, player_max_health)

# Resource methods
func add_resource(type: String, amount: int):
	match type:
		"organic":
			organic += amount
		"synthetic":
			synthetic += amount
		"data":
			data += amount
	resources_changed.emit(organic, synthetic, data)
	save_game()

# Power methods
func change_power(amount: float):
	if is_game_over:
		return
	player_power = clamp(player_power + amount, 0.0, player_max_power)
	power_changed.emit(player_power, player_max_power)

# Memory / Overdrive methods
func add_memory(amount: float):
	if is_game_over or is_overdrive:
		return
	player_memory = min(player_max_memory, player_memory + amount)
	memory_changed.emit(player_memory, player_max_memory)
	if player_memory >= player_max_memory:
		trigger_overdrive()

func trigger_overdrive():
	is_overdrive = true
	overdrive_timer = overdrive_duration
	overdrive_state_changed.emit(true)

# Upgrade Shop methods
func get_upgrade_cost(upgrade_name: String) -> Dictionary:
	var lvl = upgrades[upgrade_name]
	if lvl >= max_upgrades[upgrade_name]:
		return {} # Max level reached
		
	match upgrade_name:
		"speed":
			return {"organic": 10 + lvl * 10}
		"health":
			return {"synthetic": 10 + lvl * 10}
		"cooldown":
			return {"data": 10 + lvl * 10}
		"split_shot":
			return {"synthetic": 30, "data": 20}
		"photosynthesis":
			return {"organic": 15 + lvl * 10, "data": 5 + lvl * 5}
		"dash_energy":
			return {"synthetic": 12 + lvl * 8, "organic": 8 + lvl * 5}
	return {}

func purchase_upgrade(upgrade_name: String) -> bool:
	if is_game_over:
		return false
		
	var cost = get_upgrade_cost(upgrade_name)
	if cost.is_empty():
		return false # Max level or invalid
		
	# Check if can afford
	var org_cost = cost.get("organic", 0)
	var syn_cost = cost.get("synthetic", 0)
	var dat_cost = cost.get("data", 0)
	
	if organic >= org_cost and synthetic >= syn_cost and data >= dat_cost:
		organic -= org_cost
		synthetic -= syn_cost
		data -= dat_cost
		resources_changed.emit(organic, synthetic, data)
		
		upgrades[upgrade_name] += 1
		var new_level = upgrades[upgrade_name]
		
		# Apply immediate effects
		if upgrade_name == "health":
			player_max_health += 20
			player_health += 20
			health_changed.emit(player_health, player_max_health)
			
		upgrade_purchased.emit(upgrade_name, new_level)
		save_game()
		return true
		
	return false

func change_sector(sector_name: String):
	print("Sector changed: ", sector_name)

func restart():
	score = 0
	wave = 0
	player_max_health = 100
	player_health = player_max_health
	is_game_over = false
	
	organic = 0
	synthetic = 0
	data = 0
	player_power = 100.0
	player_max_power = 100.0
	player_memory = 0.0
	is_overdrive = false
	overdrive_timer = 0.0
	kill_count = 0
	
	for key in upgrades:
		upgrades[key] = 0
		
	score_changed.emit(score)
	wave_changed.emit(wave)
	health_changed.emit(player_health, player_max_health)
	resources_changed.emit(organic, synthetic, data)
	power_changed.emit(player_power, player_max_power)
	memory_changed.emit(player_memory, player_max_memory)
	overdrive_state_changed.emit(is_overdrive)
	save_game()

func save_game():
	var save_dict = {
		"upgrades": upgrades,
		"organic": organic,
		"synthetic": synthetic,
		"data": data,
		"score": score
	}
	var file = FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if file:
		file.store_string(JSON.stringify(save_dict))
		file.close()

func load_game():
	if not FileAccess.file_exists(SAVE_PATH):
		return
	var file = FileAccess.open(SAVE_PATH, FileAccess.READ)
	if file:
		var content = file.get_as_text()
		var json = JSON.new()
		var parse_result = json.parse(content)
		if parse_result == OK:
			var data_dict = json.get_data()
			if typeof(data_dict) == TYPE_DICTIONARY:
				if data_dict.has("upgrades"):
					for key in data_dict["upgrades"]:
						if upgrades.has(key):
							upgrades[key] = int(data_dict["upgrades"][key])
							# Apply health upgrade effect to max health
							if key == "health":
								player_max_health += 20 * int(data_dict["upgrades"][key])
								player_health = player_max_health
				if data_dict.has("organic"): organic = int(data_dict["organic"])
				if data_dict.has("synthetic"): synthetic = int(data_dict["synthetic"])
				if data_dict.has("data"): self.data = int(data_dict["data"])
				if data_dict.has("score"): 
					score = int(data_dict["score"])
					score_changed.emit(score)
		file.close()
		
		# Emit initialization signals
		health_changed.emit(player_health, player_max_health)
		resources_changed.emit(organic, synthetic, data)

func load_global_settings():
	var cfg = ConfigFile.new()
	if cfg.load("user://neon_bloom_settings.cfg") == OK:
		var sfx_vol = cfg.get_value("audio", "sfx_volume", -6.0)
		var music_vol = cfg.get_value("audio", "music_volume", -12.0)
		var fullscreen = cfg.get_value("display", "fullscreen", false)
		if fullscreen:
			DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN)
		MusicPlayer.set_volume(music_vol)
		if SoundFX.get_child_count() > 0:
			var p = SoundFX.get_child(0)
			if p is AudioStreamPlayer:
				p.volume_db = sfx_vol

func _restore_time_scale():
	var timer = get_tree().create_timer(0.08)
	timer.timeout.connect(_do_restore_time_scale)

func _do_restore_time_scale():
	var tween = create_tween()
	tween.tween_method(_set_time_scale, Engine.time_scale, 1.0, 0.35)
	
func _set_time_scale(val: float):
	Engine.time_scale = val
