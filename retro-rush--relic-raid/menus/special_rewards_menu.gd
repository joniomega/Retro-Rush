extends Control


# Called when the node enters the scene tree for the first time.
var reward1:String
var reward2:String
var reward3:String
@onready var admob = $Admob
var is_initialized : bool = false
func _ready() -> void:
	#INITIALIZE ADMOB
	admob.initialize()
	update()
func update():
	if is_initialized:
		$takeall/AnimatedSprite2D.play("ad")
		$takeall/Label.modulate = Color(1, 1, 1, 1)
		$takeall/AnimatedSprite2D.modulate = Color(1, 1, 1, 1)
		$takeall/Button_takeall.disabled = false
		
	else:
		$takeall/AnimatedSprite2D.play("noad")
		$takeall/Label.modulate = Color(0.5, 0.5, 0.5, 0.5)
		$takeall/AnimatedSprite2D.modulate = Color(0.5, 0.5, 0.5, 0.5)
		$takeall/Button_takeall.disabled = true
	pass # Replace with function body.
func setup_rewards():
	# Generate all possible ingredients
	var all_ingredients := []
	for item_type in Global.CRAFTABLE_ITEMS:
		for item in Global.CRAFTABLE_ITEMS[item_type]:
			all_ingredients.append(item + "_1")
			all_ingredients.append(item + "_2")
	
	# Filter out already collected ingredients
	var available_ingredients = []
	for ingredient in all_ingredients:
		if not Global.collected_ingredients.get(ingredient, false):
			available_ingredients.append(ingredient)
	
	# Select rewards from remaining ingredients
	reward1 = ""
	reward2 = ""
	reward3 = ""
	
	if available_ingredients.size() >= 1:
		reward1 = available_ingredients.pick_random()
		available_ingredients.erase(reward1)
	
	if available_ingredients.size() >= 1:
		reward2 = available_ingredients.pick_random()
		available_ingredients.erase(reward2)
	
	if available_ingredients.size() >= 1:
		reward3 = available_ingredients.pick_random()
		available_ingredients.erase(reward3)
	
	# Setup rewards display
	$ingredient_reward1.setup(reward1)
	$ingredient_reward2.setup(reward2)
	$ingredient_reward3.setup(reward3)

func _on_admob_initialization_completed(status_data: InitializationStatus) -> void:
	is_initialized = true
	update()
	pass # Replace with function body.


func _on_button_takeall_pressed() -> void:
	if is_initialized == true:
		$takeall/Label.modulate = Color(0.5, 0.5, 0.5, 0.5)
		$takeall/AnimatedSprite2D.modulate = Color(0.5, 0.5, 0.5, 0.5)
		$takeall/Button_takeall.disabled = true
		admob.load_rewarded_ad()
		await admob.rewarded_ad_loaded
		admob.show_rewarded_ad()
	pass # Replace with function body.


func _on_admob_rewarded_ad_user_earned_reward(ad_id: String, reward_data: RewardItem) -> void:
	Global.collect_ingredient(reward1)
	Global.collect_ingredient(reward2)
	Global.collect_ingredient(reward3)
	var tree = get_tree()
	TransitionScreen.transition()
	await TransitionScreen.on_transition_finished
	tree.change_scene_to_file("res://menus/mainmenu.tscn")
	pass # Replace with function body.
