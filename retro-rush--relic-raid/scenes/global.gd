extends Node

# Game Progress
var selected_level: int = 1
var selected_level_special: bool = false
var unlocked_levels: Array = [1]
var points: int = 1000

# Player Customization
const ALL_HATS := ["none", "hat", "spikes", "plant", "crest", "books"]
const ALL_SKINS := ["1", "2", "3", "4", "5"]

var player_hat: String = "none"
var player_skin: String = "1"
var unlocked_hats: Array = []
var unlocked_skins: Array = []

# Crafting System
const CRAFTABLE_ITEMS := {
	"accessories": ["hat", "spikes", "plant", "crest", "books"],
	"skins": ["2", "3", "4", "5"]
}

var collected_ingredients: Dictionary = {}
var unlocked_rewards: Dictionary = {}

func _ready() -> void:
	# Initialize ingredients
	for item_type in CRAFTABLE_ITEMS:
		for item in CRAFTABLE_ITEMS[item_type]:
			collected_ingredients[item + "_1"] = false
			collected_ingredients[item + "_2"] = false
			unlocked_rewards[item] = false
	
	# Default unlocked items
	unlocked_rewards["1"] = true
	
	load_progress()
	update_unlocked_items()

func update_unlocked_items():
	unlocked_hats = ["none"]  # Start with just "none"
	unlocked_skins = ["1"]    # Start with just "1"
	
	# Add unlocked hats (skip "none" since we already added it)
	for hat in ALL_HATS:
		if hat != "none" and unlocked_rewards.get(hat, false):
			unlocked_hats.append(hat)
	
	# Add unlocked skins (skip "1" since we already added it)
	for skin in ALL_SKINS:
		if skin != "1" and unlocked_rewards.get(skin, false):
			unlocked_skins.append(skin)

func save_progress() -> void:
	var save_data = {
		"unlocked_levels": unlocked_levels,
		"points": points,
		"player_hat": player_hat,
		"player_skin": player_skin,
		"collected_ingredients": collected_ingredients,
		"unlocked_rewards": unlocked_rewards,
		"unlocked_hats": unlocked_hats,
		"unlocked_skins": unlocked_skins
	}
	
	var file = FileAccess.open("user://save.dat", FileAccess.WRITE)
	if file:
		file.store_var(save_data)
	else:
		push_error("Failed to save game: ", FileAccess.get_open_error())

func load_progress() -> void:
	if not FileAccess.file_exists("user://save.dat"):
		return
	
	var file = FileAccess.open("user://save.dat", FileAccess.READ)
	if file:
		var save_data = file.get_var()
		
		unlocked_levels = save_data.get("unlocked_levels", [1])
		points = save_data.get("points", 1000)
		player_hat = save_data.get("player_hat", "none")
		player_skin = save_data.get("player_skin", "1")
		collected_ingredients = save_data.get("collected_ingredients", {})
		unlocked_rewards = save_data.get("unlocked_rewards", {})
		unlocked_hats = save_data.get("unlocked_hats", ["none"])
		unlocked_skins = save_data.get("unlocked_skins", ["1"])
		
		# Ensure new items are tracked
		for item_type in CRAFTABLE_ITEMS:
			for item in CRAFTABLE_ITEMS[item_type]:
				if not collected_ingredients.has(item + "_1"):
					collected_ingredients[item + "_1"] = false
				if not collected_ingredients.has(item + "_2"):
					collected_ingredients[item + "_2"] = false
				if not unlocked_rewards.has(item):
					unlocked_rewards[item] = false
		
		update_unlocked_items()
	else:
		push_error("Failed to load game: ", FileAccess.get_open_error())

func unlock_next_level(current_level: int) -> void:
	if not unlocked_levels.has(current_level + 1):
		unlocked_levels.append(current_level + 1)
		save_progress()

func collect_ingredient(ingredient: String) -> void:
	if collected_ingredients.has(ingredient):
		collected_ingredients[ingredient] = true
		save_progress()

func unlock_reward(reward: String) -> void:
	if (reward in CRAFTABLE_ITEMS["accessories"] or 
		reward in CRAFTABLE_ITEMS["skins"]):
		
		unlocked_rewards[reward] = true
		update_unlocked_items()
		save_progress()
