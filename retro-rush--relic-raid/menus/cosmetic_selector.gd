extends Control

# Nodes (resolved at runtime to avoid null path errors)
var button: Button
var animated_sprite_accessory: AnimatedSprite2D
var animated_sprite_skin: AnimatedSprite2D

enum CosmeticType { HAT, SKIN }

@export var cosmetic_name: String
@export var cosmetic_type: CosmeticType
@export var customization_menu: Node  # keep as Node (set in inspector) or leave null
@export var is_unlocked: bool = false

# resolved menu node (may be same as `customization_menu` or discovered up the tree)
var _menu_node: Node = null

func _ready() -> void:
	$IconExclamation.visible = false
	if Global.unlocked_recent == cosmetic_name:
		$IconExclamation.visible = true
	# Resolve node references safely
	button = get_node_or_null("Button") as Button
	animated_sprite_accessory = get_node_or_null("reward_accessory") as AnimatedSprite2D
	animated_sprite_skin = get_node_or_null("reward_skin") as AnimatedSprite2D

	# Prepare visuals
	if animated_sprite_accessory:
		animated_sprite_accessory.visible = false
	if animated_sprite_skin:
		animated_sprite_skin.visible = false
	if has_node("Bald"):
		$Bald.visible = false
		if cosmetic_name == "none":
			$Bald.visible = true

	# Show preview animation if available (safely)
	if cosmetic_type == CosmeticType.HAT and animated_sprite_accessory:
		animated_sprite_accessory.visible = true
		if animated_sprite_accessory.sprite_frames and animated_sprite_accessory.sprite_frames.has_animation(cosmetic_name + "_jump"):
			animated_sprite_accessory.play(cosmetic_name + "_jump")
	elif cosmetic_type == CosmeticType.SKIN and animated_sprite_skin:
		animated_sprite_skin.visible = true
		if animated_sprite_skin.sprite_frames and animated_sprite_skin.sprite_frames.has_animation(cosmetic_name + "_jump"):
			animated_sprite_skin.play(cosmetic_name + "_jump")

	# Resolve and store menu node (inspector assigned or search upward)
	_menu_node = _resolve_menu_node()
	# Locked check (refreshes is_unlocked and button state)
	refresh_lock_state()

	# Apply greying if locked
	if button and button.disabled:
		if animated_sprite_accessory:
			animated_sprite_accessory.modulate = Color(0.5, 0.5, 0.5)
		if animated_sprite_skin:
			animated_sprite_skin.modulate = Color(0.5, 0.5, 0.5)

	# Register this selector in the customization menu if available
	if _menu_node and _menu_node.has_method("register_cosmetic_selector"):
		_menu_node.register_cosmetic_selector(self)


# Attempt to resolve the customization menu:
# 1) use inspector-set `customization_menu` if present
# 2) else climb parents to find the first node that implements register_cosmetic_selector
func _resolve_menu_node() -> Node:
	if customization_menu:
		# If the inspector assigned an actual Node, use it
		if customization_menu is Node:
			return customization_menu
	# Fallback: search parents for a node that has register_cosmetic_selector
	var p: Node = get_parent()
	while p:
		if p.has_method("register_cosmetic_selector"):
			return p
		p = p.get_parent()
	return null


func refresh_lock_state() -> void:
	# Update the unlocked boolean based on Global lists
	if cosmetic_type == CosmeticType.HAT:
		is_unlocked = Global.unlocked_hats.has(cosmetic_name)
	elif cosmetic_type == CosmeticType.SKIN:
		is_unlocked = Global.unlocked_skins.has(cosmetic_name)

	# Only set button.disabled if we actually resolved a button
	if button:
		button.disabled = not is_unlocked
	else:
		# Helpful debug print but not required in release
		# print_warning("cosmetic_selector: Button node not found for ", cosmetic_name)
		pass

	# Update visual modulation based on unlocked state (safe-guards)
	if animated_sprite_accessory:
		animated_sprite_accessory.modulate = Color(1, 1, 1) if is_unlocked else Color(0.5, 0.5, 0.5)
	if animated_sprite_skin:
		animated_sprite_skin.modulate = Color(1, 1, 1) if is_unlocked else Color(0.5, 0.5, 0.5)


func _on_button_pressed() -> void:
	if Global.unlocked_recent == cosmetic_name:
		$IconExclamation.visible = false
		Global.unlocked_recent = ""
	# Play press sound if exists
	if has_node("button_press"):
		$button_press.play()

	# Only act if unlocked and menu exists
	if cosmetic_type == CosmeticType.HAT and is_unlocked and _menu_node:
		if _menu_node.has_method("select_hat"):
			_menu_node.select_hat(cosmetic_name)
	elif cosmetic_type == CosmeticType.SKIN and is_unlocked and _menu_node:
		if _menu_node.has_method("select_skin"):
			_menu_node.select_skin(cosmetic_name)
