extends Node2D

@onready var audio_collect = $AudioStreamPlayer
@onready var animation = $AnimatedSprite2D

var random_anim : String
var global
func _ready() -> void:
	# Play the chosen animation
	global = Global
	animation.play(str(global.selected_level))
	if global.selected_level_special == true:
		var holo_material = preload("res://assets/shaders/holo.tres")
		$AnimatedSprite2D.material = holo_material
	pass
func _on_area_2d_body_entered(body: Node2D) -> void:
	if body.is_in_group("player"):
		audio_collect.play()
		$AudioStreamPlayer2.play()
		body.shine(250)
		#body.win(str(global.selected_level))
		$AnimatedSprite2D.visible=false
		global.unlock_next_level(global.selected_level)
		if global.selected_level_special == true:
			body.win_special(str(global.selected_level))
			global.selected_level_special = false
			pass
		else:
			body.win(str(global.selected_level))
	pass # Replace with function body.
