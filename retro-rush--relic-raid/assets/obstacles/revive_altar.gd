extends Node2D
var active = false

func _on_area_2d_body_entered(body: Node2D) -> void:
	if body.is_in_group("player") and active == false:
		active = true
		Global.revival = body.global_position
		$AnimatedSprite2D.play("active")
		$CPUParticles2D2.emitting = true
		$sound_revive.play()
		pass
