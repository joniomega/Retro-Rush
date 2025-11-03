extends Node2D
var isonrewards = false
var global = Global
@onready var goto_levels = $static_ui/menu/levels
@onready var menu_levels = $levels
@onready var goto_craft = $static_ui/menu/craft
@onready var menu_craft = $craft
@onready var goto_rewards = $static_ui/menu/rewards
@onready var menu_rewards = $rewards

@onready var levels_scroll = $levels/ScrollContainer
@onready var bottompart = $static_ui/menu

# Store original positions
var level_pos: Vector2
var craft_pos: Vector2
var reward_pos: Vector2
var current_menu = "levels"

# Swipe detection variables
var swipe_start = null
var minimum_drag = 100  # Minimum pixels to consider it a swipe

# Colors for button highlight
const ACTIVE_COLOR := Color(1.2, 1.2, 0.4, 1.0)
const INACTIVE_COLOR := Color(1, 1, 1, 1)

func _ready() -> void:
	# CHECK IF LVL 1 IS COMPLETE:
	if global.unlocked_levels.size() == 1 and global.unlocked_levels[0] == 1:
		global.selected_level = 1
		var tree = get_tree()
		tree.change_scene_to_file("res://scenes/lvl_0.tscn")
		return
	$static_ui/menu/craft/IconExclamation.visible = false
	if global.unlocked_recent != "":
		$static_ui/menu/craft/IconExclamation.visible = true
	global.selected_level = 0
	global.revival = null
	global.selected_level_special = false
	$static_ui/points.text = "[left][b][color=#b0ace6]" + str(global.points)+"c" + "[/color][/b][/left]"
	if global.points == 0:
		$static_ui/points.text = "[left][wave][color=#b0ace6][b]0[/b][/color][/wave][/left]"
	
	# Save initial positions
	level_pos = menu_levels.position
	craft_pos = menu_craft.position
	reward_pos = menu_rewards.position
	
	# Highlight levels button by default
	_set_menu_highlight(goto_levels)
	
	# Hide other menus initially
	menu_craft.position.x = -get_viewport_rect().size.x
	menu_rewards.position.x = get_viewport_rect().size.x
	
	# Scroll to last unlocked level
	update_level_scroll()
	var textlist = ["Back to work!", "Find me relics!","Ready to work?", "Welcome back."]
	$static_ui/menu/TextureRect/SpeechBubble/Label.text = textlist[randi_range(0, 3)]
	$static_ui/menu/TextureRect/Animationtalk.play("talk")
	$audio_talk.play()

func update_level_scroll():
	if global.unlocked_levels.size() > 0:
		var target_scroll = (global.unlocked_levels.max() - 1) * 60
		create_tween().tween_property(levels_scroll, "scroll_vertical", target_scroll, 1.5).set_trans(Tween.TRANS_QUINT)

func move_menus(target_menu: String):
	var tween = create_tween().set_trans(Tween.TRANS_QUINT).set_ease(Tween.EASE_OUT)
	var duration = 0.3  # Reduced duration for swipe responsiveness
	
	match target_menu:
		"levels":
			tween.tween_property(menu_levels, "position", level_pos, duration)
			tween.parallel().tween_property(menu_craft, "position", Vector2(-get_viewport_rect().size.x, craft_pos.y), duration)
			tween.parallel().tween_property(menu_rewards, "position", Vector2(get_viewport_rect().size.x, reward_pos.y), duration)
			_set_menu_highlight(goto_levels)
			
		"craft":
			tween.tween_property(menu_levels, "position", Vector2(get_viewport_rect().size.x, level_pos.y), duration)
			tween.parallel().tween_property(menu_craft, "position", level_pos, duration)
			tween.parallel().tween_property(menu_rewards, "position", Vector2(get_viewport_rect().size.x * 2, reward_pos.y), duration)
			_set_menu_highlight(goto_craft)
			
		"rewards":
			tween.tween_property(menu_levels, "position", Vector2(-get_viewport_rect().size.x, level_pos.y), duration)
			tween.parallel().tween_property(menu_craft, "position", Vector2(-get_viewport_rect().size.x * 2, craft_pos.y), duration)
			tween.parallel().tween_property(menu_rewards, "position", level_pos, duration)
			_set_menu_highlight(goto_rewards)
	
	current_menu = target_menu

func _set_menu_highlight(active_button: Button) -> void:
	# Reset all buttons to inactive
	goto_levels.modulate = INACTIVE_COLOR
	goto_craft.modulate = INACTIVE_COLOR
	goto_rewards.modulate = INACTIVE_COLOR
	
	# Highlight the active one
	active_button.modulate = ACTIVE_COLOR

func _on_levels_pressed() -> void:
	$button_press.play()
	if current_menu != "levels":
		move_menus("levels")
	if isonrewards == true:
		isonrewards = false
		$rewards/rewards_menu.ui_down()

func _on_craft_pressed() -> void:
	$static_ui/menu/craft/IconExclamation.visible = false
	$button_press.play()
	if current_menu != "craft":
		move_menus("craft")
	if isonrewards == true:
		isonrewards = false
		$rewards/rewards_menu.ui_down()

func _on_rewards_pressed() -> void:
	isonrewards = true
	$button_press.play()
	if current_menu != "rewards":
		move_menus("rewards")
	$rewards/rewards_menu.ui_up()

# Improved touch input handling for swipe detection
func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventScreenTouch:
		if event.pressed:
			swipe_start = event.position
		elif swipe_start != null:  # Only detect swipe if we had a start position
			_swipe_detect(event.position)
			swipe_start = null
	
	# Also allow mouse swipes for testing in editor
	if event is InputEventMouseButton:
		if event.pressed:
			swipe_start = event.position
		elif swipe_start != null:  # Only detect swipe if we had a start position
			_swipe_detect(event.position)
			swipe_start = null

func _swipe_detect(end_position: Vector2) -> void:
	if swipe_start == null:
		return
	
	var swipe = end_position - swipe_start
	
	# Only consider horizontal swipes
	if abs(swipe.x) > minimum_drag and abs(swipe.x) > abs(swipe.y):
		$button_press.play()  # Play sound on swipe
		
		if swipe.x > 0:  # Swipe right
			match current_menu:
				"levels":
					move_menus("craft")
				"craft":
					move_menus("rewards")
				"rewards":
					move_menus("levels")  # Wrap around
		
		elif swipe.x < 0:  # Swipe left
			match current_menu:
				"levels":
					move_menus("rewards")  # Wrap around
				"craft":
					move_menus("levels")
				"rewards":
					move_menus("craft")


func _on_button_settings_pressed() -> void:
	$button_press.play()
	var options_menu = preload("res://menus/options_menu.tscn").instantiate()
	options_menu.is_online = $rewards/rewards_menu.is_online
	add_child(options_menu) # adds on top of the menu (OptionsMenu root must be a Control with full rect)
	pass # Replace with function body.


func _on_button_pressed() -> void:
	pass # Replace with function body.


func _on_talk_pressed() -> void:
	var textlist = ["Back to work!", "Find me relics!","Look for gold.", "Bewere of bugs."]
	$static_ui/menu/TextureRect/SpeechBubble/Label.text = textlist[randi_range(0, 3)]
	$static_ui/menu/TextureRect/Animationtalk.play("talk")
	$audio_talk.play()
	pass # Replace with function body.
