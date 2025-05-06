extends Control

@export var level_num : int = 0
var global
@onready var button = $Button
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
	9: "Sribe's Rest"
}
func _ready() -> void:
	var levelvars = [1, 2, 3, 4, 5, 6, 7, 8, 9]
	level_num = (levelvars[randi() % levelvars.size()])
	global = Global
	$Label.text = str(level_num, "- ", level_names.get(level_num, "Unknown Ruins"))
	$AnimatedSprite2D.play(str(level_num))

func _on_button_pressed() -> void:
	global.selected_level = level_num
	var tree = get_tree()
	TransitionScreen.transition()
	await TransitionScreen.on_transition_finished
	tree.change_scene_to_file("res://scenes/lvl_0.tscn")
