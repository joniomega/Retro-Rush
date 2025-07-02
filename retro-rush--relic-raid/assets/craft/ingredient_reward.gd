extends Node2D

@onready var animation := $ingredients_animation
@export var ingredient: String = "none"

func _ready() -> void:
	
	# Generate all possible ingredients
	#var all_ingredients := []
	#for item_type in Global.CRAFTABLE_ITEMS:
		#for item in Global.CRAFTABLE_ITEMS[item_type]:
			#all_ingredients.append(item + "_1")
			#all_ingredients.append(item + "_2")
	#ingredient = all_ingredients[randi() % all_ingredients.size()]
	#animation.play(ingredient)
	pass
func setup(reward:String):
	ingredient = reward
	animation.play(ingredient)
	await get_tree().create_timer(1).timeout
	if ingredient == "none":
		$Button.disabled = true
		self.visible = false
	if ingredient == "":
		$Button.disabled = true
		self.visible = false

func _on_button_pressed() -> void:
	Global.collect_ingredient(ingredient)
	var tree = get_tree()
	TransitionScreen.transition()
	await TransitionScreen.on_transition_finished
	tree.change_scene_to_file("res://menus/mainmenu.tscn")
