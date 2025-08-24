extends Control

@onready var button = $Button
@onready var animated_sprite_accessory = $reward_accessory
@onready var animated_sprite_skin = $reward_skin

@export var cosmetic_name: String
@export var cosmetic_type: String
@export var customization_menu: Node

func _ready() -> void:
	animated_sprite_accessory.visible = false
	animated_sprite_skin.visible = false

func setup_selector(name: String, type: String, menu: Node) -> void:
	cosmetic_name = name
	cosmetic_type = type
	customization_menu = menu

	# Show preview animation
	if cosmetic_type == "hat":
		animated_sprite_accessory.visible = true
		animated_sprite_accessory.play(cosmetic_name + "_jump")
	elif cosmetic_type == "skin":
		animated_sprite_skin.visible = true
		animated_sprite_skin.play(cosmetic_name + "_jump")

	# Locked check uses Global
	if cosmetic_type == "hat":
		button.disabled = not Global.unlocked_hats.has(cosmetic_name)
	elif cosmetic_type == "skin":
		button.disabled = not Global.unlocked_skins.has(cosmetic_name)

func _on_button_pressed() -> void:
	if cosmetic_type == "hat" and Global.unlocked_hats.has(cosmetic_name):
		customization_menu.select_hat(cosmetic_name)
	elif cosmetic_type == "skin" and Global.unlocked_skins.has(cosmetic_name):
		customization_menu.select_skin(cosmetic_name)
