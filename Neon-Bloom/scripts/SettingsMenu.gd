extends Control

var sfx_db: float = -6.0
var music_db: float = -12.0
var sfx_slider: HSlider
var music_slider: HSlider
var fullscreen_btn: Button

func _ready():
	setup_background()
	setup_panel()
	setup_content()
	load_settings()

func setup_background():
	var dim = ColorRect.new()
	dim.color = Color(0.0, 0.0, 0.0, 0.6)
	dim.anchor_right = 1.0
	dim.anchor_bottom = 1.0
	dim.mouse_filter = Control.MOUSE_FILTER_STOP
	dim.gui_input.connect(_on_bg_click)
	add_child(dim)

func _on_bg_click(event):
	if event is InputEventMouseButton and event.pressed:
		SoundFX.play("shoot", -14.0)
		save_settings()
		queue_free()

func setup_panel():
	var panel = Panel.new()
	panel.anchor_left = 0.5
	panel.anchor_top = 0.5
	panel.anchor_right = 0.5
	panel.anchor_bottom = 0.5
	panel.offset_left = -280
	panel.offset_top = -220
	panel.offset_right = 280
	panel.offset_bottom = 220

	var style = StyleBoxFlat.new()
	style.bg_color = Color(0.03, 0.03, 0.06, 0.95)
	style.border_width_left = 2
	style.border_width_top = 2
	style.border_width_right = 2
	style.border_width_bottom = 2
	style.border_color = Color(0.0, 1.0, 0.8, 0.4)
	style.corner_radius_top_left = 10
	style.corner_radius_top_right = 10
	style.corner_radius_bottom_right = 10
	style.corner_radius_bottom_left = 10
	panel.add_theme_stylebox_override("panel", style)
	add_child(panel)

func setup_content():
	var m = MarginContainer.new()
	m.offset_left = 20
	m.offset_top = 20
	m.offset_right = -20
	m.offset_bottom = -20
	m.anchors_preset = Control.PRESET_FULL_RECT
	$".".get_child(1).add_child(m)

	var vbox = VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 16)
	m.add_child(vbox)

	var title = Label.new()
	title.text = "SETTINGS"
	title.add_theme_font_size_override("font_size", 32)
	title.add_theme_color_override("font_color", Color(0.0, 1.0, 0.8))
	title.add_theme_color_override("font_outline_color", Color.BLACK)
	title.add_theme_constant_override("outline_size", 4)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(title)

	vbox.add_child(_section_label("Audio"))
	vbox.add_child(_slider_row("SFX Volume", "sfx"))
	vbox.add_child(_slider_row("Music Volume", "music"))
	vbox.add_child(_section_label("Display"))
	vbox.add_child(_button_row("Fullscreen", "fullscreen"))
	vbox.add_child(_section_label("Controls"))
	var controls_label = _info_label("WASD: Move  |  LMB/Space: Shoot")
	vbox.add_child(controls_label)
	var controls_label2 = _info_label("RMB/Shift: Dash  |  E: Evolve Shop")
	vbox.add_child(controls_label2)

	var close_btn = Button.new()
	close_btn.text = "CLOSE"
	close_btn.custom_minimum_size = Vector2(200, 40)
	close_btn.add_theme_font_size_override("font_size", 18)
	close_btn.add_theme_color_override("font_color", Color(0.0, 1.0, 0.8))
	close_btn.add_theme_color_override("font_hover_color", Color(1, 1, 1))
	var cb = StyleBoxFlat.new()
	cb.bg_color = Color(0.05, 0.1, 0.08, 0.7)
	cb.border_width_left = 2
	cb.border_width_top = 2
	cb.border_width_right = 2
	cb.border_width_bottom = 2
	cb.border_color = Color(0.0, 0.8, 0.6, 0.4)
	cb.corner_radius_top_left = 4
	cb.corner_radius_top_right = 4
	cb.corner_radius_bottom_right = 4
	cb.corner_radius_bottom_left = 4
	close_btn.add_theme_stylebox_override("normal", cb)
	close_btn.pressed.connect(func(): SoundFX.play("shoot", -14.0); save_settings(); queue_free())
	vbox.add_child(_spacer())

	var center_wrapper = HBoxContainer.new()
	center_wrapper.add_theme_constant_override("separation", 0)
	var spacer_l = Control.new()
	spacer_l.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	center_wrapper.add_child(spacer_l)
	center_wrapper.add_child(close_btn)
	var spacer_r = Control.new()
	spacer_r.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	center_wrapper.add_child(spacer_r)
	vbox.add_child(center_wrapper)

func _spacer() -> Control:
	var c = Control.new()
	c.custom_minimum_size = Vector2(0, 8)
	return c

func _section_label(text: String) -> Label:
	var lbl = Label.new()
	lbl.text = text
	lbl.add_theme_font_size_override("font_size", 16)
	lbl.add_theme_color_override("font_color", Color(0.4, 0.9, 0.9))
	return lbl

func _info_label(text: String) -> Label:
	var lbl = Label.new()
	lbl.text = text
	lbl.add_theme_font_size_override("font_size", 14)
	lbl.add_theme_color_override("font_color", Color(0.5, 0.5, 0.6))
	return lbl

func _slider_row(label_text: String, id: String) -> HBoxContainer:
	var row = HBoxContainer.new()
	row.add_theme_constant_override("separation", 12)

	var lbl = Label.new()
	lbl.text = label_text
	lbl.add_theme_font_size_override("font_size", 18)
	lbl.add_theme_color_override("font_color", Color(0.8, 0.8, 0.9))
	lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(lbl)

	var slider = HSlider.new()
	slider.custom_minimum_size = Vector2(180, 24)
	slider.min_value = -40.0
	slider.max_value = 0.0
	slider.step = 1.0
	slider.value = -6.0
	slider.value_changed.connect(func(v): _on_volume_change(id, v))
	row.add_child(slider)

	var val_label = Label.new()
	val_label.text = "%d dB" % int(slider.value)
	val_label.add_theme_font_size_override("font_size", 14)
	val_label.add_theme_color_override("font_color", Color(0.6, 0.6, 0.7))
	val_label.custom_minimum_size = Vector2(50, 0)
	row.add_child(val_label)

	slider.value_changed.connect(func(v): val_label.text = "%d dB" % int(v))

	return row

func _button_row(label_text: String, id: String) -> HBoxContainer:
	var row = HBoxContainer.new()
	var lbl = Label.new()
	lbl.text = label_text
	lbl.add_theme_font_size_override("font_size", 18)
	lbl.add_theme_color_override("font_color", Color(0.8, 0.8, 0.9))
	lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(lbl)

	fullscreen_btn = Button.new()
	fullscreen_btn.text = "OFF"
	fullscreen_btn.custom_minimum_size = Vector2(100, 36)
	fullscreen_btn.add_theme_font_size_override("font_size", 16)
	fullscreen_btn.add_theme_color_override("font_color", Color(0.8, 0.8, 0.9))
	var btn_norm = StyleBoxFlat.new()
	btn_norm.bg_color = Color(0.1, 0.1, 0.12, 0.7)
	btn_norm.border_color = Color(0.3, 0.3, 0.4, 0.4)
	btn_norm.border_width_left = 1
	btn_norm.border_width_top = 1
	btn_norm.border_width_right = 1
	btn_norm.border_width_bottom = 1
	fullscreen_btn.add_theme_stylebox_override("normal", btn_norm)
	fullscreen_btn.pressed.connect(_on_fullscreen_toggle)
	row.add_child(fullscreen_btn)
	return row

func _on_volume_change(id: String, v: float):
	if id == "sfx":
		sfx_db = v
		SoundFX._audio_player.volume_db = v
	elif id == "music":
		music_db = v
		MusicPlayer.set_volume(v)

func _on_fullscreen_toggle():
	var mode = DisplayServer.window_get_mode()
	if mode == DisplayServer.WINDOW_MODE_FULLSCREEN:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)
		fullscreen_btn.text = "OFF"
	else:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN)
		fullscreen_btn.text = "ON"

func load_settings():
	var cfg = ConfigFile.new()
	if cfg.load("user://neon_bloom_settings.cfg") == OK:
		sfx_db = cfg.get_value("audio", "sfx_volume", -6.0)
		music_db = cfg.get_value("audio", "music_volume", -12.0)
		var fs = cfg.get_value("display", "fullscreen", false)
		if fs:
			DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN)
			if fullscreen_btn:
				fullscreen_btn.text = "ON"
		if SoundFX and SoundFX.get_child_count() > 0:
			var p = SoundFX.get_child(0)
			if p is AudioStreamPlayer:
				p.volume_db = sfx_db
		MusicPlayer.set_volume(music_db)

func save_settings():
	var cfg = ConfigFile.new()
	cfg.set_value("audio", "sfx_volume", sfx_db)
	cfg.set_value("audio", "music_volume", music_db)
	cfg.set_value("display", "fullscreen", DisplayServer.window_get_mode() == DisplayServer.WINDOW_MODE_FULLSCREEN)
	cfg.save("user://neon_bloom_settings.cfg")