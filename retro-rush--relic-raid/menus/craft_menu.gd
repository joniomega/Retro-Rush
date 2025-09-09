extends Control

@onready var hat_sprite := $equipment/AnimatedSprite2D/accessory
@onready var skin_sprite := $equipment/AnimatedSprite2D
var cosmetic_selector_hat_list: Array = []
var cosmetic_selector_skin_list: Array = []
var _pending_reorder_containers: Array = []


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
	Global.unlock_reward("spikes")
	Global.unlock_reward("crest") 
	Global.unlock_reward("books") 
	Global.unlock_reward("candle") 
	Global.unlock_reward("2") 
	Global.unlock_reward("3") 
	Global.unlock_reward("4") 
	Global.unlock_reward("5") 
	Global.unlock_reward("6") 
	Global.unlock_reward("plant") 
	Global.unlocked_recent = "plant"
	Global.save_progress()
	pass

func register_cosmetic_selector(selector: Node) -> void:
	# Track selectors by type
	if selector.cosmetic_type == selector.CosmeticType.HAT:
		cosmetic_selector_hat_list.append(selector)
	elif selector.cosmetic_type == selector.CosmeticType.SKIN:
		cosmetic_selector_skin_list.append(selector)

	# Schedule a deferred reorder for the selector's parent container
	var container: Container = selector.get_parent()
	if container and container is Container:
		# add to pending list only if not already present
		if not _pending_reorder_containers.has(container):
			_pending_reorder_containers.append(container)
			# call once deferred to process all pending containers
			call_deferred("_process_pending_reorders")


func _process_pending_reorders() -> void:
	# Called deferred (safe to modify the tree here)
	for container in _pending_reorder_containers:
		if container and container is Container:
			reorder_cosmetics(container)
	_pending_reorder_containers.clear()


func reorder_cosmetics(container: Container) -> void:
	# Build sortable entries for children that are cosmetic selectors
	var sortable: Array = []
	for child in container.get_children():
		if child and child.has_method("refresh_lock_state"):
			# Update the child's unlocked state first
			child.refresh_lock_state()

			var is_skin: bool = (child.cosmetic_type == child.CosmeticType.SKIN)
			var order_list: Array = Global.ALL_SKINS if is_skin else Global.ALL_HATS
			var idx: int = order_list.find(child.cosmetic_name)
			if idx == -1:
				idx = 9999  # fallback if not found

			var entry: Dictionary = {
				"node": child,
				"unlocked": child.is_unlocked,
				"order": idx
			}
			sortable.append(entry)

	# Sort: unlocked first; within each group keep canonical order
	sortable.sort_custom(_cmp_sortable)

	# Reorder nodes in the container to match sorted array
	# Because this function is called deferred, direct move_child is safe.
	var i: int = 0
	for item in sortable:
		var node_to_move: Node = item["node"]
		# extra safety: only move if still a child
		if node_to_move and node_to_move.get_parent() == container:
			container.move_child(node_to_move, i)
			i += 1


# Comparator: returns true if a should be placed before b
func _cmp_sortable(a: Dictionary, b: Dictionary) -> bool:
	# If unlocked states differ, unlocked (true) should come before locked (false)
	if a["unlocked"] != b["unlocked"]:
		return a["unlocked"]  # true if a unlocked (so comes first)

	# Same unlocked state -> compare canonical order
	return int(a["order"]) < int(b["order"])
