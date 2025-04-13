extends Node2D


func _on_area_2d_body_entered(body: Node2D) -> void:
	if body.is_in_group("player"):
		body.die()
		#$Timer.start()
	pass # Replace with function body.


func _on_timer_timeout() -> void:
	pass # Replace with function body.
