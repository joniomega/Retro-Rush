extends Node2D


func _on_area_2d_body_entered(body: Node2D) -> void:
	if body.is_in_group("player"):
		body.shine()
		$AnimationPlayer.play("break")
		await get_tree().create_timer(2.6).timeout
		self.queue_free()
	pass # Replace with function body.
