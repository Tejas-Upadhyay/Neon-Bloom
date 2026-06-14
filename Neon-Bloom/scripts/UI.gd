extends CanvasLayer

@onready var label = $MarginContainer/Label

func update_score(score):
	label.text = "Plants Harvested: " + str(score)
