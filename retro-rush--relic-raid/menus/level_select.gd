extends Control

@export var level_num : int = 0
var global
@onready var button = $Button

# Level name dictionary (level_num : display_name)
var level_names = {
	0: "Ruins of Otamol",
	1: "Catacombs of Reim",
	2: "Sunken Temple of Yith",
	3: "Forgotten Necropolis",
	4: "Abyssal Vaults",
	5: "Cursed Sepulcher",
	6: "Echoing Ruins"
}

func _ready() -> void:
	global = Global
	$Label.text = str(level_num, "- ", level_names.get(level_num, "Unknown Ruins"))
	
	# Determine level state and set visuals
	if !global.unlocked_levels.has(level_num):
		$CPUParticles2D2.emitting = false
		# LOCKED state
		$AnimatedSprite2D.play("lock")
		button.disabled = true
		$Label.modulate = Color(0.5, 0.5, 0.5)  # Gray out
	elif global.unlocked_levels.has(level_num + 1) || level_num == 0:
		# BEATEN state (next level is unlocked OR it's level 0)
		$AnimatedSprite2D.play(str(level_num))
		button.disabled = false
		$Label.modulate = Color(1, 1, 1)
	else:
		$CPUParticles2D2.emitting = false
		# UNLOCKED but NOT BEATEN state
		$AnimatedSprite2D.play("0")
		button.disabled = false
		$Label.modulate = Color(0.8, 0.8, 0.8)  # Slightly dimmed

func _on_button_pressed() -> void:
	global.selected_level = level_num
	var tree = get_tree()
	TransitionScreen.transition()
	await TransitionScreen.on_transition_finished
	tree.change_scene_to_file("res://scenes/lvl_0.tscn")
