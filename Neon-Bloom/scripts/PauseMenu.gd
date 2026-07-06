extends Control

func _ready():
	process_mode = Node.PROCESS_MODE_ALWAYS
	setup_background()
	setup_panel()
	show_buttons()

func _unhandled_input(event: InputEvent):
	if event is InputEventKey and event.pressed and event.keycode == KEY_ESCAPE:
		if not event.is_echo():
			_on_resume()

func setup_background():
	var dim = ColorRect.new()
	dim.color = Color(0.0, 0.0, 0.0, 0.5)
	dim.anchor_right = 1.0
	dim.anchor_bottom = 1.0
	add_child(dim)
	var tween = create_tween()
	tween.tween_property(dim, "color:a", 0.65, 0.15)

func setup_panel():
	var panel = Panel.new()
	panel.anchor_left = 0.5
	panel.anchor_top = 0.5
	panel.anchor_right = 0.5
	panel.anchor_bottom = 0.5
	panel.offset_left = -220
	panel.offset_top = -180
	panel.offset_right = 220
	panel.offset_bottom = 180

	var style = StyleBoxFlat.new()
	style.bg_color = Color(0.02, 0.02, 0.05, 0.95)
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

func show_buttons():
	var m = MarginContainer.new()
	m.offset_left = 25
	m.offset_top = 25
	m.offset_right = -25
	m.offset_bottom = -25
	m.anchors_preset = Control.PRESET_FULL_RECT
	get_child(1).add_child(m)

	var vbox = VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 12)
	m.add_child(vbox)

	var title = Label.new()
	title.text = "PAUSED"
	title.add_theme_font_size_override("font_size", 36)
	title.add_theme_color_override("font_color", Color(0.0, 1.0, 0.8))
	title.add_theme_color_override("font_outline_color", Color.BLACK)
	title.add_theme_constant_override("outline_size", 4)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(title)

	var wave_label = Label.new()
	wave_label.text = "Current Wave: " + str(GameManager.wave)
	wave_label.add_theme_font_size_override("font_size", 16)
	wave_label.add_theme_color_override("font_color", Color(1.0, 0.4, 0.8))
	wave_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(wave_label)

	vbox.add_child(_spacer())
	vbox.add_child(_btn("▶  RESUME", _on_resume))
	vbox.add_child(_spacer())
	vbox.add_child(_btn("⚙  SETTINGS", _on_settings))
	vbox.add_child(_spacer())
	vbox.add_child(_btn("↩  QUIT TO MENU", _on_quit))

func _spacer() -> Control:
	var c = Control.new()
	c.custom_minimum_size = Vector2(0, 6)
	return c

func _btn(text: String, cb: Callable) -> Button:
	var btn = Button.new()
	btn.text = text
	btn.custom_minimum_size = Vector2(280, 48)
	btn.add_theme_font_size_override("font_size", 22)
	btn.add_theme_color_override("font_color", Color(0.0, 1.0, 0.8))
	btn.add_theme_color_override("font_hover_color", Color(1.0, 1.0, 1.0))
	btn.pressed.connect(cb)

	var normal = StyleBoxFlat.new()
	normal.bg_color = Color(0.05, 0.1, 0.08, 0.7)
	normal.border_width_left = 2
	normal.border_width_top = 2
	normal.border_width_right = 2
	normal.border_width_bottom = 2
	normal.border_color = Color(0.0, 0.8, 0.6, 0.4)
	normal.corner_radius_top_left = 4
	normal.corner_radius_top_right = 4
	btn.add_theme_stylebox_override("normal", normal)

	var hover = StyleBoxFlat.new()
	hover.bg_color = Color(0.0, 0.25, 0.2, 0.85)
	hover.border_color = Color(0.0, 1.0, 0.8, 0.8)
	hover.corner_radius_top_left = 4
	hover.corner_radius_top_right = 4
	btn.add_theme_stylebox_override("hover", hover)

	return btn

func _on_resume():
	SoundFX.play("shoot", -10.0)
	get_tree().paused = false
	queue_free()

func _on_settings():
	SoundFX.play("shoot", -12.0)
	var settings = load("res://scenes/menu/SettingsMenu.tscn").instantiate()
	add_child(settings)

func _on_quit():
	get_tree().paused = false
	SoundFX.play("shoot", -10.0)
	var fade = ColorRect.new()
	fade.color = Color.BLACK
	fade.anchor_right = 1.0
	fade.anchor_bottom = 1.0
	fade.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(fade)
	fade.modulate.a = 0.0
	var tween = create_tween()
	tween.tween_property(fade, "modulate:a", 1.0, 0.5)
	tween.tween_callback(_do_quit_transition)

func _do_quit_transition():
	get_tree().change_scene_to_file("res://scenes/menu/TitleScreen.tscn")