extends Node2D

@onready var audio_collect = $AudioStreamPlayer
@onready var animation = $AnimatedSprite2D

var random_anim : String
var global
func _ready() -> void:
	# Play the chosen animation
	global = Global
	animation.play(str(global.selected_level))
	if global.ranked_opponent_score > 1:
		animation.play("ranked")
	if global.selected_level_special == true:
		pass
	pass
func _on_area_2d_body_entered(body: Node2D) -> void:
	if body.is_in_group("player"):
		audio_collect.play()
		
		body.shine(250)
		#body.win(str(global.selected_level))
		$AnimatedSprite2D.visible=false
		if Global.ranked_opponent_name == "none":
			global.unlock_next_level(global.selected_level)
			#if global.selected_level_special == true:
				#$AudioStreamPlayer2.play()
				#body.win_special(str(global.selected_level))
				#global.selected_level_special = false
			if global.selected_level != 1:
				$AudioStreamPlayer2.play()
				body.win_special(str(global.selected_level))
				global.selected_level_special = false
			else:
				$AudioStreamPlayer2.play()
				body.win(str(global.selected_level))
		else:
			body.win_ranked(str(global.ranked_level))
		
	pass # Replace with function body.
