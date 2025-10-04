extends Node2D

@export var skin: String = "6"
@export var playername: String = ""

func _ready() -> void:
	$CanvasLayer.visible = true
	# Check if player has the same name
	# Check if player already has this skin
	if Global.unlocked_skins.has(skin):
		self.visible = false
		queue_free()
		return
	
	# If both conditions pass, show the reward
	self.visible = true

func _on_button_pressed() -> void:
	# Claim the skin using Global function
	Global.unlock_reward(skin)
	
	# Optional: Show some feedback or play sound
	print("Claimed skin: ", skin)
	var tree = get_tree()
	TransitionScreen.transition()
	await TransitionScreen.on_transition_finished
	tree.change_scene_to_file("res://menus/mainmenu.tscn")
