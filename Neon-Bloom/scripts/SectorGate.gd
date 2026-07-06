extends Area2D

@export var target_sector: String = ""
@export var gate_color: Color = Color(0.5, 0.8, 1)

var pulse_phase: float = 0.0

@onready var sprite: Sprite2D = $Sprite2D

func _ready():
	add_to_group("sector_gate")
	if sprite:
		sprite.modulate = gate_color

func _process(delta):
	pulse_phase += delta * 2.0
	if sprite:
		var pulse = 0.6 + sin(pulse_phase) * 0.4
		sprite.modulate = Color(gate_color.r, gate_color.g, gate_color.b, pulse)

func enter():
	GameManager.change_sector(target_sector)

func _on_body_entered(body):
	if body.is_in_group("player"):
		enter()
