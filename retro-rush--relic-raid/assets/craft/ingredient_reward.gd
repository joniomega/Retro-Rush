extends Node2D


# Called when the node enters the scene tree for the first time.
@export var ingridient = "0"
var ingredientslist = ["cowboy_1", "cowboy_2", "flower_1", "flower_2"]
@onready var animation = $ingredients_animation
func _ready() -> void:
	ingridient = ingredientslist[randi() % ingredientslist.size()]
	animation.play(ingridient)
	
	pass # Replace with function body.


func _on_button_pressed() -> void:
	var tree = get_tree()
	TransitionScreen.transition()
	await TransitionScreen.on_transition_finished
	tree.change_scene_to_file("res://menus/mainmenu.tscn")
	pass # Replace with function body.
