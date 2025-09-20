extends Node2D
var right = false

func _ready() -> void:
	if right == true:
		$AnimationPlayer.play("trap_right")
	else:
		$AnimationPlayer.play("trap_left")

func _on_area_2d_body_entered(body: Node2D) -> void:
	if body.is_in_group("player"):
		if Global.ranked_opponent_name == "none":
			body.die()
		else:
			body.shine(-body.score)
			body.die_ranked()
	pass # Replace with function body.
