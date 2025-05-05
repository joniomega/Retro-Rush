extends Control

@export var reward: String = ""  # Can be accessory or skin
@onready var button := $Button
@onready var unlocked_button := $Button2
@onready var accessory_display := $reward_accessory
@onready var skin_display := $reward_skin
@onready var icon_ad := $IconAd

func _ready() -> void:
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
	
	if !(has_part1 and has_part2):
		button.disabled = true
		icon_ad.modulate = Color(0.5, 0.5, 0.5, 0.5)
	# Update main display color
	var main_display = accessory_display if reward in Global.CRAFTABLE_ITEMS["accessories"] else skin_display
	main_display.modulate = Color.WHITE if (has_part1 and has_part2) else Color(0.5, 0.5, 0.5, 0.5)

func _on_button_pressed():
	var has_both = (
		Global.collected_ingredients.get(reward + "_1", false) &&
		Global.collected_ingredients.get(reward + "_2", false))
	
	if has_both:
		Global.unlock_reward(reward)
		self.modulate = Color(0.5, 0.5, 0.5, 0.5)
		await get_tree().create_timer(0.5).timeout
		show_unlocked()
