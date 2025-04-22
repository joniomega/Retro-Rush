extends Node2D

@onready var audio_collect = $AudioStreamPlayer
@onready var animation = $AnimatedSprite2D
var random_anim : String
var global
func _ready() -> void:
	# List of possible animations
	#var animations = ["sword", "skull", "crown", "orb","mask","harp"]
	# Pick a random animation
	#random_anim = animations[randi() % animations.size()]
	# Play the chosen animation
	global = Global
	animation.play(str(global.selected_level))
	pass

func _on_area_2d_body_entered(body: Node2D) -> void:
	if body.is_in_group("player"):
		audio_collect.play()
		$AudioStreamPlayer2.play()
		body.win(str(global.selected_level))
		body.shine(250)
		$AnimatedSprite2D.visible=false
		global.unlock_next_level(global.selected_level)
	pass # Replace with function body.
