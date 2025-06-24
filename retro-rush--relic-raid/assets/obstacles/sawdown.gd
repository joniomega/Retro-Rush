extends Node2D


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.

func _on_area_2d_body_entered(body: Node2D) -> void:
	if body.is_in_group("player"):
		if Global.ranked_opponent_name == "none":
			body.die()
		else:
			body.die_ranked()
	pass # Replace with function body.
