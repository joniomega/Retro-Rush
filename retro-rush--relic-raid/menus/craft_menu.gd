extends Control

@onready var hat_sprite := $equipment/AnimatedSprite2D/accessory
@onready var skin_sprite := $equipment/AnimatedSprite2D

var current_hat_index := 0
var current_skin_index := 0

func _ready() -> void:
	# Ensure valid defaults
	if Global.player_hat.is_empty() or Global.unlocked_hats.is_empty():
		Global.player_hat = "none"
	if Global.player_skin.is_empty() or Global.unlocked_skins.is_empty():
		Global.player_skin = "1"
	
	load_player_customization()
	update_display()

func load_player_customization():
	current_hat_index = Global.unlocked_hats.find(Global.player_hat)
	if current_hat_index == -1:
		current_hat_index = 0
		Global.player_hat = Global.unlocked_hats[0] if !Global.unlocked_hats.is_empty() else "none"
	
	current_skin_index = Global.unlocked_skins.find(Global.player_skin)
	if current_skin_index == -1:
		current_skin_index = 0
		Global.player_skin = Global.unlocked_skins[0] if !Global.unlocked_skins.is_empty() else "1"

func update_display():
	update_hat_display()
	update_skin_display()

func update_hat_display():
	if !Global.unlocked_hats.is_empty() and current_hat_index < Global.unlocked_hats.size():
		Global.player_hat = Global.unlocked_hats[current_hat_index]
		hat_sprite.play(Global.player_hat + "_jump")
		Global.save_progress()

func update_skin_display():
	if !Global.unlocked_skins.is_empty() and current_skin_index < Global.unlocked_skins.size():
		Global.player_skin = Global.unlocked_skins[current_skin_index]
		skin_sprite.play(Global.player_skin + "_jump")
		Global.save_progress()

func _on_button_hat_right_pressed():
	if Global.unlocked_hats.size() > 1:
		current_hat_index = (current_hat_index + 1) % Global.unlocked_hats.size()
		update_hat_display()

func _on_button_hat_left_pressed():
	if Global.unlocked_hats.size() > 1:
		current_hat_index = (current_hat_index - 1) % Global.unlocked_hats.size()
		if current_hat_index < 0:
			current_hat_index = Global.unlocked_hats.size() - 1
		update_hat_display()

func _on_button_body_right_pressed():
	if Global.unlocked_skins.size() > 1:
		current_skin_index = (current_skin_index + 1) % Global.unlocked_skins.size()
		update_skin_display()

func _on_button_body_left_pressed():
	if Global.unlocked_skins.size() > 1:
		current_skin_index = (current_skin_index - 1) % Global.unlocked_skins.size()
		if current_skin_index < 0:
			current_skin_index = Global.unlocked_skins.size() - 1
		update_skin_display()
