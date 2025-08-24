extends Control

@onready var hat_sprite := $equipment/AnimatedSprite2D/accessory
@onready var skin_sprite := $equipment/AnimatedSprite2D



var current_hat_index := 0
var current_skin_index := 0

func _ready() -> void:
	if Global.player_hat.is_empty():
		Global.player_hat = "none"
	if Global.player_skin.is_empty():
		Global.player_skin = "1"
	
	load_player_customization()
	update_display()

func load_player_customization():
	current_hat_index = Global.ALL_HATS.find(Global.player_hat)
	if current_hat_index == -1:
		current_hat_index = 0
		Global.player_hat = "none"
	
	current_skin_index = Global.ALL_SKINS.find(Global.player_skin)
	if current_skin_index == -1:
		current_skin_index = 0
		Global.player_skin = "1"

func update_display():
	update_hat_display()
	update_skin_display()

func update_hat_display():
	if current_hat_index >= 0 and current_hat_index < Global.ALL_HATS.size():
		Global.player_hat = Global.ALL_HATS[current_hat_index]
		hat_sprite.play(Global.player_hat + "_jump")
		Global.save_progress()

func update_skin_display():
	if current_skin_index >= 0 and current_skin_index < Global.ALL_SKINS.size():
		Global.player_skin = Global.ALL_SKINS[current_skin_index]
		skin_sprite.play(Global.player_skin + "_jump")
		Global.save_progress()

func select_hat(name: String):
	var idx = Global.ALL_HATS.find(name)
	if idx != -1:
		current_hat_index = idx
		update_hat_display()

func select_skin(name: String):
	var idx = Global.ALL_SKINS.find(name)
	if idx != -1:
		current_skin_index = idx
		update_skin_display()

# Arrow buttons
func _on_button_hat_right_pressed():
	$button_press.play()
	current_hat_index = (current_hat_index + 1) % Global.ALL_HATS.size()
	update_hat_display()

func _on_button_hat_left_pressed():
	$button_press.play()
	current_hat_index = (current_hat_index - 1 + Global.ALL_HATS.size()) % Global.ALL_HATS.size()
	update_hat_display()

func _on_button_body_right_pressed():
	$button_press.play()
	current_skin_index = (current_skin_index + 1) % Global.ALL_SKINS.size()
	update_skin_display()

func _on_button_body_left_pressed():
	$button_press.play()
	current_skin_index = (current_skin_index - 1 + Global.ALL_SKINS.size()) % Global.ALL_SKINS.size()
	update_skin_display()

func _on_button_pressed() -> void:
	Global.unlock_reward("hat") 
	Global.unlock_reward("plant") 
	Global.unlock_reward("spikes")
	Global.unlock_reward("crest") 
	Global.unlock_reward("books") 
	Global.unlock_reward("horns") 
	Global.unlock_reward("2") 
	Global.unlock_reward("3") 
	Global.unlock_reward("4") 
	Global.unlock_reward("5") 
	Global.save_progress()
	pass
