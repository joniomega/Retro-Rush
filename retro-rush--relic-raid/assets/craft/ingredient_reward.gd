extends Node2D

@onready var animation := $ingredients_animation
var ingredient: String = ""

func _ready() -> void:
	# Generate all possible ingredients
	var all_ingredients := []
	for item_type in Global.CRAFTABLE_ITEMS:
		for item in Global.CRAFTABLE_ITEMS[item_type]:
			all_ingredients.append(item + "_1")
			all_ingredients.append(item + "_2")
	
	ingredient = all_ingredients[randi() % all_ingredients.size()]
	animation.play(ingredient)

func _on_button_pressed() -> void:
	Global.collect_ingredient(ingredient)
	var tree = get_tree()
	TransitionScreen.transition()
	await TransitionScreen.on_transition_finished
	tree.change_scene_to_file("res://menus/mainmenu.tscn")
