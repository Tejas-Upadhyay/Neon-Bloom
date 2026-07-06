extends Node

# Generates the station floor tiles and decorations procedurally
# Called by World._ready() to set up the visual environment

var sector_colors = {
	"Hydro Core": Color(0, 0.15, 0.2),
	"Reactor Gardens": Color(0.2, 0.05, 0.1),
	"Cryo Labs": Color(0.05, 0.1, 0.2),
	"Observation Deck": Color(0.1, 0.05, 0.15)
}

var sector_bounds = {
	"Hydro Core": Rect2(0, 0, 3000, 3000),
	"Reactor Gardens": Rect2(3000, 0, 3000, 3000),
	"Cryo Labs": Rect2(0, 3000, 3000, 3000),
	"Observation Deck": Rect2(3000, 3000, 3000, 3000)
}

func generate_floor(parent: Node2D, floor_texture: Texture2D):
	# Create a floor tile for each sector
	for sector_name in sector_bounds:
		var bounds = sector_bounds[sector_name]
		var color = sector_colors[sector_name]
		
		var rect = TextureRect.new()
		rect.texture = floor_texture
		rect.position = bounds.position
		rect.size = bounds.size
		rect.stretch_mode = TextureRect.STRETCH_TILE
		rect.modulate = color.lightened(0.3)
		parent.add_child(rect)
		rect.z_index = -10
	
	# Add sector labels
	for sector_name in sector_bounds:
		var bounds = sector_bounds[sector_name]
		var label = Label.new()
		label.text = sector_name
		label.position = bounds.position + Vector2(50, 50)
		label.add_theme_font_size_override("font_size", 48)
		label.add_theme_color_override("font_color", Color(1, 1, 1, 0.15))
		parent.add_child(label)
		label.z_index = -9
	
	# Add grid lines between sectors
	add_sector_border(parent, Vector2(3000, 0), Vector2(3000, 6000))
	add_sector_border(parent, Vector2(0, 3000), Vector2(6000, 3000))

func add_sector_border(parent: Node2D, from: Vector2, to: Vector2):
	var line = Line2D.new()
	line.add_point(from)
	line.add_point(to)
	line.width = 4.0
	line.default_color = Color(0, 1, 0.8, 0.3)
	parent.add_child(line)
	line.z_index = -8

func generate_decorations(parent: Node2D):
	# Scatter some glow particles around the station
	for i in range(40):
		var particle = CPUParticles2D.new()
		particle.position = Vector2(randf_range(100, 5900), randf_range(100, 5900))
		particle.emitting = true
		particle.amount = 4
		particle.lifetime = 3.0
		particle.one_shot = false
		particle.explosiveness = 0.0
		particle.direction = Vector2(0, -1)
		particle.spread = 30
		particle.initial_velocity_min = 5
		particle.initial_velocity_max = 15
		particle.gravity = Vector2(0, -5)
		particle.scale_amount_min = 1.0
		particle.scale_amount_max = 3.0
		particle.color = Color(0, 1, 0.8, 0.3)
		parent.add_child(particle)
		particle.z_index = -5
