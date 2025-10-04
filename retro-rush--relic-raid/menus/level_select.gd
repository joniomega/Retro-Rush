extends Control

@export var level_num : int = 0
var global
@onready var button = $Button
@onready var button_pay = $Button_pay
# Level name dictionary (level_num : display_name)
var level_names = {
	0: "Ruins of War",
	1: "Catacomb of Reim",
	2: "Sunken Temple of Yith",
	3: "Forgotten Necropolis",
	4: "Abyssal Vault",
	5: "Cursed Sepulcher",
	6: "Echoing Ruin",
	7: "Silent Temple",
	8: "Gilded Vault",
	9: "Scribe's Rest",
	10: "Ashen Crypt",
	11: "Dust Chasm",
	12: "Bone Altar",
	13: "Hushed Catacomb",
	14: "Elder Vault",
	15: "Drowned Shrine",
	16: "Vein Passage",
	17: "Obsidian Tomb",
	18: "Hollow Sanctum",
	19: "Wraith Hall",
	20: "Chalice Crypt",
	21: "Shrouded Maw",
	22: "Lost Ossuary",
	23: "Blighted Chapel",
	24: "Grim's Flute",
	25: "Forsaken Reliquary",
	26: "Weeping Grotto",
	27: "Sanguine Bow",
	28: "Hag's Hollow",
	29: "Thorned Vault",
	30: "Happy Place"
}
func _ready() -> void:
	global = Global
	$Label.text = str(level_num, "- ", level_names.get(level_num, "Unknown Ruins"))
	$Button_pay.visible = false
	# Determine level state and set visuals
	if !global.unlocked_levels.has(level_num):
		$CPUParticles2D2.emitting = false
		# LOCKED state
		$AnimatedSprite2D.play("lock")
		button.disabled = true
		button_pay.disabled = true
		$Label.modulate = Color(0.5, 0.5, 0.5)  # Gray out
		#check if level ends with 5 or 0
		if level_num % 3 == 0 or level_num == 1:
			button.visible = false
			button_pay.visible = true
			$Label.text = $Label.text+" -500c"
			$AnimatedSprite2D.play("coin_lock")
	elif global.unlocked_levels.has(level_num + 1) || level_num == 0:
		# BEATEN state (next level is unlocked OR it's level 0)
		$AnimatedSprite2D.play(str(level_num))
		button.disabled = false
		button_pay.disabled = false
		$Label.modulate = Color(1, 1, 1)
		if global.points >=500:
			button_pay.disabled = false
		else:
			button_pay.disabled = true
	else:
		$CPUParticles2D2.emitting = true
		# UNLOCKED but NOT BEATEN state
		$AnimatedSprite2D.play("0")
		button.disabled = false
		button_pay.disabled = false
		$Label.modulate = Color(0.8, 0.8, 0.8)  # Slightly dimmed
		#check if level ends with 5 or 0
		if level_num % 3 == 0 or level_num == 1:
			button.visible = false
			button_pay.visible = true
			$Label.text = $Label.text+"/ 500p"
			$AnimatedSprite2D.play("coin")

func _on_button_pressed() -> void:
	
	global.selected_level = level_num
	var tree = get_tree()
	TransitionScreen.transition()
	await TransitionScreen.on_transition_finished
	tree.change_scene_to_file("res://scenes/lvl_0.tscn")


func _on_button_pay_pressed() -> void:
	
	global.points = global.points - 500
	global.selected_level_special = true
	global.selected_level = level_num
	var tree = get_tree()
	TransitionScreen.transition()
	await TransitionScreen.on_transition_finished
	tree.change_scene_to_file("res://scenes/lvl_0.tscn")
	pass # Replace with function body.
