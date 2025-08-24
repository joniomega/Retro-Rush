extends Control

@onready var button = $Button
@onready var animated_sprite_accessory = $reward_accessory
@onready var animated_sprite_skin = $reward_skin

enum CosmeticType { HAT, SKIN }

@export var cosmetic_name: String
@export var cosmetic_type: CosmeticType
@export var customization_menu: Node

func _ready() -> void:
	animated_sprite_accessory.visible = false
	animated_sprite_skin.visible = false
	$Bald.visible = false
	if cosmetic_name == "none":
		$Bald.visible = true
	# Show preview animation
	if cosmetic_type == CosmeticType.HAT:
		animated_sprite_accessory.visible = true
		if animated_sprite_accessory.sprite_frames.has_animation(cosmetic_name + "_jump"):
			animated_sprite_accessory.play(cosmetic_name + "_jump")
	elif cosmetic_type == CosmeticType.SKIN:
		animated_sprite_skin.visible = true
		if animated_sprite_skin.sprite_frames.has_animation(cosmetic_name + "_jump"):
			animated_sprite_skin.play(cosmetic_name + "_jump")
	# Locked check
	refresh_lock_state()
	if button.disabled == true:
		animated_sprite_accessory.modulate = Color(0.5, 0.5, 0.5)
		animated_sprite_skin.modulate = Color(0.5, 0.5, 0.5)


func refresh_lock_state() -> void:
	if cosmetic_type == CosmeticType.HAT:
		button.disabled = not Global.unlocked_hats.has(cosmetic_name)
	elif cosmetic_type == CosmeticType.SKIN:
		button.disabled = not Global.unlocked_skins.has(cosmetic_name)


func _on_button_pressed() -> void:
	if cosmetic_type == CosmeticType.HAT and Global.unlocked_hats.has(cosmetic_name):
		customization_menu.select_hat(cosmetic_name)
	elif cosmetic_type == CosmeticType.SKIN and Global.unlocked_skins.has(cosmetic_name):
		customization_menu.select_skin(cosmetic_name)
