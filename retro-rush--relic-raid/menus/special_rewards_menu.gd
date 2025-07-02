extends Control

var reward1: String
var reward2: String
@onready var admob = $Admob
var is_initialized: bool = false
var has_internet: bool = false
var connectivity_check_timer: Timer
var all_collected: bool = false  # Track if all ingredients are collected

func _ready() -> void:
	# Set up periodic internet checks
	connectivity_check_timer = Timer.new()
	add_child(connectivity_check_timer)
	connectivity_check_timer.timeout.connect(_check_internet_connectivity)
	connectivity_check_timer.start(5.0)  # Check every 5 seconds
	
	# Initial internet check
	_check_internet_connectivity()
	
	setup_rewards()
	update()

func _check_internet_connectivity():
	var http_request = HTTPRequest.new()
	http_request.timeout = 3  # Set timeout property directly
	add_child(http_request)
	http_request.request_completed.connect(_on_connectivity_check_completed.bind(http_request))
	
	var error = http_request.request("https://www.google.com/favicon.ico")
	if error != OK:
		http_request.queue_free()
		_handle_internet_status(false)

func _on_connectivity_check_completed(result: int, response_code: int, headers: PackedStringArray, body: PackedByteArray, http_request: HTTPRequest):
	http_request.queue_free()
	_handle_internet_status(response_code == 200)

func _handle_internet_status(connected: bool):
	if has_internet != connected:
		has_internet = connected
		print("Internet connection ", "restored" if connected else "lost")
		
		# Initialize AdMob only when we have internet
		if has_internet and !is_initialized:
			admob.initialize()
		
		update()

func update():
	var can_show_ad = is_initialized and has_internet
	
	if can_show_ad:
		$takeall/AnimatedSprite2D.play("ad")
		$takeall/Label.modulate = Color(1, 1, 1, 1)
		$takeall/AnimatedSprite2D.modulate = Color(1, 1, 1, 1)
		$takeall/Button_takeall.disabled = false
	else:
		$takeall/AnimatedSprite2D.play("noad")
		$takeall/Label.modulate = Color(0.5, 0.5, 0.5, 0.5)
		$takeall/AnimatedSprite2D.modulate = Color(0.5, 0.5, 0.5, 0.5)
		$takeall/Button_takeall.disabled = true

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
	
	# Check if all ingredients are collected
	if available_ingredients.size() == 0:
		all_collected = true
		$ingredient_reward1.visible = false
		$ingredient_reward2.visible = false
		$takeall/Label.text = "+500p"
		return
	
	# Shuffle the available ingredients to randomize selection order
	available_ingredients.shuffle()
	
	# Select rewards - try to find matching pairs first
	reward1 = ""
	reward2 = ""
	
	if available_ingredients.size() >= 1:
		# First try to find a pair where we have one part available
		for ingredient in available_ingredients:
			var base_name = ingredient.substr(0, ingredient.length() - 2)  # Remove "_1" or "_2"
			var counterpart = base_name + ("_2" if ingredient.ends_with("_1") else "_1")
			
			if counterpart in available_ingredients:
				reward1 = ingredient
				reward2 = counterpart
				available_ingredients.erase(ingredient)
				available_ingredients.erase(counterpart)
				break
		
		# If no pairs found, pick random ingredients
		if reward1 == "":
			reward1 = available_ingredients.pick_random()
			available_ingredients.erase(reward1)
			
			if available_ingredients.size() >= 1:
				reward2 = available_ingredients.pick_random()
				available_ingredients.erase(reward2)
	
	# Setup rewards display
	$ingredient_reward1.setup(reward1)
	$ingredient_reward2.setup(reward2)

func _on_admob_initialization_completed(status_data: InitializationStatus) -> void:
	is_initialized = true
	update()

func _on_button_takeall_pressed() -> void:
	if is_initialized and has_internet:
		$takeall/Label.modulate = Color(0.5, 0.5, 0.5, 0.5)
		$takeall/AnimatedSprite2D.modulate = Color(0.5, 0.5, 0.5, 0.5)
		$takeall/Button_takeall.disabled = true
		admob.load_rewarded_ad()
		await admob.rewarded_ad_loaded
		admob.show_rewarded_ad()

func _on_admob_rewarded_ad_user_earned_reward(ad_id: String, reward_data: RewardItem) -> void:
	if all_collected:
		# Give 500 points when all ingredients are collected
		Global.points += 500
		Global.save_progress()
	else:
		# Collect ingredients normally
		if reward1 != "":
			Global.collect_ingredient(reward1)
		if reward2 != "":
			Global.collect_ingredient(reward2)
	
	var tree = get_tree()
	TransitionScreen.transition()
	await TransitionScreen.on_transition_finished
	tree.change_scene_to_file("res://menus/mainmenu.tscn")
