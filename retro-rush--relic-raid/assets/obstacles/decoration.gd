extends Node2D
@onready var animated_sprite = $AnimatedSprite2D
func _ready() -> void:
	var random_index = str(randi_range(1, 5))
	animated_sprite.play(random_index)
	pass
