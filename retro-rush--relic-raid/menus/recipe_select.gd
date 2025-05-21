extends Control

@export var reward: String = ""  # Can be accessory or skin
@onready var button := $Button
@onready var unlocked_button := $Button2
@onready var accessory_display := $reward_accessory
@onready var skin_display := $reward_skin
# ADS
@onready var icon_ad := $IconAd
@onready var icon_nowifi := $IconNoWifi
@onready var admob = $Admob

var is_initialized: bool = false
var clicked_ad: bool = false
var has_internet: bool = false
var connectivity_check_timer: Timer

func _ready() -> void:
	# Set up periodic internet connectivity checks
	connectivity_check_timer = Timer.new()
	add_child(connectivity_check_timer)
	connectivity_check_timer.timeout.connect(_check_internet_connectivity)
	connectivity_check_timer.start(5.0)  # Check every 5 seconds
	
	# Initial internet check
	_check_internet_connectivity()
	
	assert(
		reward in Global.CRAFTABLE_ITEMS["accessories"] or 
		reward in Global.CRAFTABLE_ITEMS["skins"],
		"Invalid reward type: " + reward
	)
	
	unlocked_button.visible = false
	accessory_display.visible = false
	skin_display.visible = false
	
	if Global.unlocked_rewards.get(reward, false):
		show_unlocked()
	else:
		update_recipe_display()

func _check_internet_connectivity():
	var http_request = HTTPRequest.new()
	http_request.timeout = 3  # Set timeout here
	add_child(http_request)
	http_request.request_completed.connect(_on_connectivity_check_completed.bind(http_request))
	
	# Correct request call with 4 arguments
	var error = http_request.request("https://www.google.com/favicon.ico", [], HTTPClient.METHOD_GET, "")
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
		
		update_recipe_display()

func show_unlocked():
	button.visible = false
	unlocked_button.visible = true
	
	if reward in Global.CRAFTABLE_ITEMS["accessories"]:
		$Button2/reward_accessory2.play(reward + "_jump")
	else:
		$Button2/reward_skin2.play(reward + "_jump")
	
	await get_tree().create_timer(0.5).timeout
	queue_free()

func update_recipe_display():
	var has_part1 = Global.collected_ingredients.get(reward + "_1", false)
	var has_part2 = Global.collected_ingredients.get(reward + "_2", false)
	
	$ingredients1.play(reward + "_1")
	$ingredients2.play(reward + "_2")
	
	if reward in Global.CRAFTABLE_ITEMS["accessories"]:
		accessory_display.visible = true
		accessory_display.play(reward + "_jump")
		$Button2/reward_accessory2.play(reward + "_jump")
	else:
		skin_display.visible = true
		skin_display.play(reward + "_jump")
		$Button2/reward_skin2.play(reward + "_jump")
	
	$ingredients1.modulate = Color.WHITE if has_part1 else Color(0.5, 0.5, 0.5, 0.5)
	$ingredients2.modulate = Color.WHITE if has_part2 else Color(0.5, 0.5, 0.5, 0.5)
	
	var can_show_ad = is_initialized and has_internet
	
	if !(has_part1 and has_part2):
		button.disabled = true
		icon_ad.visible = can_show_ad
		icon_nowifi.visible = !can_show_ad
		icon_ad.modulate = Color(0.5, 0.5, 0.5, 0.5)
	else:
		button.disabled = !can_show_ad
		icon_ad.visible = can_show_ad
		icon_nowifi.visible = !can_show_ad
		icon_ad.modulate = Color.WHITE if can_show_ad else Color(0.5, 0.5, 0.5, 0.5)
	
	var main_display = accessory_display if reward in Global.CRAFTABLE_ITEMS["accessories"] else skin_display
	main_display.modulate = Color.WHITE if (has_part1 and has_part2) else Color(0.5, 0.5, 0.5, 0.5)

func _on_button_pressed():
	var has_both = (
		Global.collected_ingredients.get(reward + "_1", false) &&
		Global.collected_ingredients.get(reward + "_2", false))
	
	if has_both and is_initialized and has_internet:
		$Label.queue_free()
		$ingredients1.queue_free()
		$ingredients2.queue_free()
		
		if reward in Global.CRAFTABLE_ITEMS["accessories"]:
			$reward_accessory.modulate = Color(1.5, 1.5, 1.5, 1)
		else:
			$reward_skin.modulate = Color(1.5, 1.5, 1.5, 1)
		
		icon_ad.modulate = Color(1.5, 1.5, 1.5, 1)
		
		admob.load_rewarded_ad()
		await admob.rewarded_ad_loaded
		admob.show_rewarded_ad()
		clicked_ad = true

func _on_admob_initialization_completed(status_data):
	is_initialized = true
	update_recipe_display()

func _on_admob_rewarded_ad_user_earned_reward(ad_id: String, reward_data: RewardItem):
	if clicked_ad:
		Global.unlock_reward(reward)
		button.disabled = true
		await get_tree().create_timer(0.5).timeout
		show_unlocked()
		clicked_ad = false
