extends Node2D
@onready var animated_sprite = $AnimatedSprite2D
func _ready() -> void:
	var random_index = str(randi_range(1, 9))
	animated_sprite.play(random_index)
	var flip = str(randi() % 2)  # "0" or "1"
	animated_sprite.flip_h = flip == "1"  # Convert to boolean
	pass
