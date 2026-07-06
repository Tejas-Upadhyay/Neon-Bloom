extends Control

func _ready():
	MusicPlayer.play_music("menu")
	setup_background()
	setup_animated_logo()
	setup_buttons()

func _draw():
	var vp_size = get_viewport_rect().size
	var grid_size = 60.0
	var x := 0.0
	while x <= vp_size.x:
		var c = Color(0.1, 0.8, 0.7, 0.03)
		draw_line(Vector2(x, 0), Vector2(x, vp_size.y), c)
		x += grid_size
	var y := 0.0
	while y <= vp_size.y:
		var c = Color(0.1, 0.8, 0.7, 0.03)
		draw_line(Vector2(0, y), Vector2(vp_size.x, y), c)
		y += grid_size

func setup_background():
	var dark = ColorRect.new()
	dark.color = Color(0.01, 0.01, 0.04)
	dark.anchor_right = 1.0
	dark.anchor_bottom = 1.0
	add_child(dark)
	move_child(dark, 0)

func setup_animated_logo():
	var logo = Label.new()
	logo.text = "NEON  BLOOM"
	logo.add_theme_font_size_override("font_size", 80)
	logo.add_theme_color_override("font_color", Color(0.0, 1.0, 0.8))
	logo.add_theme_color_override("font_outline_color", Color(0.0, 0.2, 0.2))
	logo.add_theme_constant_override("outline_size", 8)
	logo.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	logo.anchor_left = 0.5
	logo.anchor_top = 0.32
	logo.anchor_right = 0.5
	logo.offset_left = -320
	logo.offset_top = -40
	logo.offset_right = 320
	logo.offset_bottom = 60
	add_child(logo)

	var sub = Label.new()
	sub.text = "A Neon Survival Experience"
	sub.add_theme_font_size_override("font_size", 18)
	sub.add_theme_color_override("font_color", Color(0.4, 0.9, 0.9))
	sub.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	sub.anchor_left = 0.5
	sub.anchor_top = 0.39
	sub.anchor_right = 0.5
	sub.offset_left = -200
	sub.offset_right = 200
	sub.offset_bottom = 30
	add_child(sub)

func setup_buttons():
	var container = VBoxContainer.new()
	container.anchor_left = 0.5
	container.anchor_top = 0.55
	container.anchor_right = 0.5
	container.offset_left = -140
	container.offset_right = 140
	container.add_theme_constant_override("separation", 14)
	add_child(container)

	container.add_child(_spacer())
	container.add_child(_btn("▶  PLAY", _on_play))
	container.add_child(_spacer())
	container.add_child(_btn("⚙  SETTINGS", _on_settings))
	container.add_child(_spacer())
	container.add_child(_btn("✕  QUIT", _on_quit))

func _spacer() -> Control:
	var c = Control.new()
	c.custom_minimum_size = Vector2(0, 6)
	return c

func _btn(text: String, cb: Callable) -> Button:
	var btn = Button.new()
	btn.text = text
	btn.custom_minimum_size = Vector2(280, 52)
	btn.add_theme_font_size_override("font_size", 24)
	btn.add_theme_color_override("font_color", Color(0.0, 1.0, 0.8))
	btn.add_theme_color_override("font_hover_color", Color(1.0, 1.0, 1.0))
	btn.pressed.connect(cb)

	var normal = StyleBoxFlat.new()
	normal.bg_color = Color(0.04, 0.08, 0.06, 0.7)
	normal.border_width_left = 2
	normal.border_width_top = 2
	normal.border_width_right = 2
	normal.border_width_bottom = 2
	normal.border_color = Color(0.0, 0.8, 0.6, 0.4)
	normal.corner_radius_top_left = 4
	normal.corner_radius_top_right = 4
	normal.corner_radius_bottom_right = 4
	normal.corner_radius_bottom_left = 4
	btn.add_theme_stylebox_override("normal", normal)

	var hover = StyleBoxFlat.new()
	hover.bg_color = Color(0.0, 0.25, 0.2, 0.85)
	hover.border_width_left = 2
	hover.border_width_top = 2
	hover.border_width_right = 2
	hover.border_width_bottom = 2
	hover.border_color = Color(0.0, 1.0, 0.8, 0.8)
	hover.corner_radius_top_left = 4
	hover.corner_radius_top_right = 4
	hover.corner_radius_bottom_right = 4
	hover.corner_radius_bottom_left = 4
	btn.add_theme_stylebox_override("hover", hover)

	var pressed = StyleBoxFlat.new()
	pressed.bg_color = Color(0.0, 0.15, 0.1, 0.9)
	pressed.border_color = Color(0.0, 1.0, 0.6, 0.6)
	pressed.corner_radius_top_left = 4
	pressed.corner_radius_top_right = 4
	pressed.corner_radius_bottom_right = 4
	pressed.corner_radius_bottom_left = 4
	btn.add_theme_stylebox_override("pressed", pressed)

	return btn

func _on_play():
	SoundFX.play("upgrade", -6.0)
	GameManager.restart()
	DirAccess.remove_absolute("user://neon_bloom_save.json")
	MusicPlayer.set_volume(-40.0)
	var fade = ColorRect.new()
	fade.color = Color.BLACK
	fade.anchor_right = 1.0
	fade.anchor_bottom = 1.0
	fade.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(fade)
	fade.modulate.a = 0.0
	var tween = create_tween()
	tween.tween_property(fade, "modulate:a", 1.0, 0.6)
	tween.tween_callback(_trans_to_game)

func _trans_to_game():
	get_tree().change_scene_to_file("res://scenes/world/World.tscn")

func _on_settings():
	SoundFX.play("shoot", -12.0)
	var settings = load("res://scenes/menu/SettingsMenu.tscn").instantiate()
	add_child(settings)

func _on_quit():
	get_tree().quit()