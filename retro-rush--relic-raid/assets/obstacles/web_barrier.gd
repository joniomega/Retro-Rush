extends Node2D
var state = 3

func _on_area_2d_body_entered(body: Node2D) -> void:
	if state != 0:
		if body.is_in_group("player"):
			$CPUParticles2D.restart()
			$CPUParticles2D.emitting = true
			$sound_break.play()
			state = state -1
			$AnimatedSprite2D.play(str(state))
			body.velocity.y = -200
