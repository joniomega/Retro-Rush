extends Control

@export var reward: String = ""  # Can be accessory or skin
@onready var button := $Button
@onready var unlocked_button := $Button2
@onready var accessory_display := $reward_accessory
@onready var skin_display := $reward_skin
#ADS
@onready var icon_ad:= $IconAd
@onready var icon_nowifi:= $IconNoWifi
@onready var admob = $Admob
var is_initialized : bool = false
var clicked_ad : bool = false

func _ready() -> void:
	#INITIALIZE ADMOB
	admob.initialize()
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

func show_unlocked():
	#AAAAAAAAAAAAA FOR FUTURE
	queue_free()
	button.visible = false
	unlocked_button.visible = true
	if reward in Global.CRAFTABLE_ITEMS["accessories"]:
		$Button2/reward_accessory2.play(reward + "_jump")
	else:
		$Button2/reward_skin2.play(reward + "_jump")

func update_recipe_display():
	var has_part1 = Global.collected_ingredients.get(reward + "_1", false)
	var has_part2 = Global.collected_ingredients.get(reward + "_2", false)
	$ingredients1.play(reward + "_1")
	$ingredients2.play(reward + "_2")
	# Show the correct display based on reward type
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
	if !(has_part1 and has_part2)and is_initialized == true:
		button.disabled = true
		icon_ad.visible = true
		icon_nowifi.visible = false
		icon_ad.modulate= Color(0.5, 0.5, 0.5, 0.5)
	if is_initialized == false:
		icon_ad.visible = false
		icon_nowifi.visible = true
		button.disabled = true
	if (has_part1 and has_part2) and is_initialized == true:
		icon_ad.visible = true
		icon_nowifi.visible = false
		button.disabled = false
		icon_ad.modulate= Color(1, 1, 1, 1)
		#LOAD AD INCASE IT IS CLICKED
		#admob.load_rewarded_ad()
	
	# Update main display color
	var main_display = accessory_display if reward in Global.CRAFTABLE_ITEMS["accessories"] else skin_display
	main_display.modulate = Color.WHITE if (has_part1 and has_part2) else Color(0.5, 0.5, 0.5, 0.5)

func _on_button_pressed():
	var has_both = (
		Global.collected_ingredients.get(reward + "_1", false) &&
		Global.collected_ingredients.get(reward + "_2", false))
	
	if has_both:
		if is_initialized:
			$Label.queue_free()
			$ingredients1.queue_free()
			$ingredients2.queue_free()
			$reward_accessory.modulate = Color(1.5, 1.5, 1.5, 1)
			$reward_skin.modulate = Color(1.5, 1.5, 1.5, 1)
			$IconAd.modulate = Color(1.5, 1.5, 1.5, 1)
			admob.load_rewarded_ad()
			await admob.rewarded_ad_loaded
			admob.show_rewarded_ad()
			clicked_ad = true
		#Global.unlock_reward(reward)
		#self.modulate = Color(0.5, 0.5, 0.5, 0.5)
		#await get_tree().create_timer(0.5).timeout
		#show_unlocked()


func _on_admob_initialization_completed(status_data: InitializationStatus) -> void:
	is_initialized = true
	update_recipe_display()
	pass # Replace with function body.


func _on_admob_rewarded_ad_user_earned_reward(ad_id: String, reward_data: RewardItem) -> void:
	if clicked_ad == true:
		Global.unlock_reward(reward)
		button.disabled = true
		await get_tree().create_timer(0.5).timeout
		show_unlocked()
	pass # Replace with function body.
