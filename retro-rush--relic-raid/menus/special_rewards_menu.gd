extends Control

var reward: String
@onready var admob = $Admob
var is_initialized: bool = false
var has_internet: bool = false
var connectivity_check_timer: Timer
var all_collected: bool = false

func _ready() -> void:
	# Periodic internet checks
	connectivity_check_timer = Timer.new()
	add_child(connectivity_check_timer)
	connectivity_check_timer.timeout.connect(_check_internet_connectivity)
	connectivity_check_timer.start(5.0)
	
	_check_internet_connectivity()
	
	setup_rewards()
	update()

func _check_internet_connectivity():
	var http_request = HTTPRequest.new()
	http_request.timeout = 3
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
		
		if has_internet and !is_initialized:
			admob.initialize()
		
	update()

func update():
	var can_show_ad = is_initialized and has_internet
	
	# Reward stays visible no matter what
	if can_show_ad:
		$takeall/AnimatedSprite2D.play("ad")
		$takeall/Label.modulate = Color(1, 1, 1, 1)
		$takeall/AnimatedSprite2D.modulate = Color(1, 1, 1, 1)
		$takeall/Button_takeall.disabled = false
	else:
		$takeall/AnimatedSprite2D.play("noad")
		$takeall/Label.modulate = Color(1, 1, 1, 1) # keep text visible
		$takeall/AnimatedSprite2D.modulate = Color(1, 1, 1, 1) # keep reward visible
		$takeall/Button_takeall.disabled = true

func setup_rewards():
	# Collect all possible rewards
	var all_rewards := []
	all_rewards.append_array(Global.ALL_HATS.filter(func(h): return h != "none"))
	all_rewards.append_array(Global.ALL_SKINS.filter(func(s): return s != "1"))

	# Filter out already unlocked
	var available_rewards = []
	for reward_item in all_rewards:
		if not Global.unlocked_rewards.get(reward_item, false):
			available_rewards.append(reward_item)

	# If none left, fallback to points
	if available_rewards.size() == 0:
		all_collected = true
		$takeall/Label.text = "+500p"
		$takeall/reward_accessory.visible = false
		$takeall/reward_skin.visible = false
		return
	
	all_collected = false
	available_rewards.shuffle()
	reward = available_rewards.pick_random()

	# Show correct sprite animation
	if reward in Global.ALL_HATS:
		$takeall/reward_accessory.visible = true
		$takeall/reward_skin.visible = false
		$takeall/reward_accessory.play(reward + "_jump")
	elif reward in Global.ALL_SKINS:
		$takeall/reward_skin.visible = true
		$takeall/reward_accessory.visible = false
		$takeall/reward_skin.play(reward + "_jump")
	
	$takeall/Label.text = "GET"

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
		Global.points += 500
		Global.save_progress()
	else:
		if reward != "":
			Global.unlock_reward(reward)
			Global.unlocked_recent = reward
	
	var tree = get_tree()
	TransitionScreen.transition()
	await TransitionScreen.on_transition_finished
	tree.change_scene_to_file("res://menus/mainmenu.tscn")
