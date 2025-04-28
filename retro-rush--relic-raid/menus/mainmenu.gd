extends Node2D

var global = Global
@onready var goto_levels = $static_ui/levels
@onready var menu_levels = $levels
@onready var goto_craft = $static_ui/craft
@onready var menu_craft = $craft
@onready var goto_rewards = $static_ui/rewards
@onready var menu_rewards = $rewards

@onready var levels_scroll = $levels/ScrollContainer
# Store original positions
var level_pos: Vector2
var craft_pos: Vector2
var reward_pos: Vector2
var current_menu = "levels"

func _ready() -> void:
	global.selected_level = 0
	global.selected_level_special = false
	$static_ui/points.text = "[wave][color=#5c3aa1][b]"+str(global.points)+"p[/b][/color][/wave]"
	if global.points == 0:
		$static_ui/points.text = "[wave][color=#5c3aa1][b]"+"000"+"p[/b][/color][/wave]"
	# Save initial positions
	level_pos = menu_levels.position
	craft_pos = menu_craft.position
	reward_pos = menu_rewards.position
	
	# Focus levels button by default
	goto_levels.grab_focus()
	
	# Hide other menus initially
	menu_craft.position.x = -get_viewport_rect().size.x
	menu_rewards.position.x = get_viewport_rect().size.x
	
	# Scroll to last unlocked level
	update_level_scroll()

func update_level_scroll():
	if global.unlocked_levels.size() > 0:
		var target_scroll = (global.unlocked_levels.max() - 1) * 60
		create_tween().tween_property(levels_scroll, "scroll_vertical", 
			target_scroll, 1.5).set_trans(Tween.TRANS_QUINT)

func move_menus(target_menu: String):
	var tween = create_tween().set_trans(Tween.TRANS_QUINT).set_ease(Tween.EASE_OUT)
	var duration = 1
	match target_menu:
		"levels":
			tween.tween_property(menu_levels, "position", level_pos, duration)
			tween.parallel().tween_property(menu_craft, "position", 
				Vector2(-get_viewport_rect().size.x, craft_pos.y), duration)
			tween.parallel().tween_property(menu_rewards, "position", 
				Vector2(get_viewport_rect().size.x, reward_pos.y), duration)
			goto_levels.grab_focus()
			
		"craft":
			tween.tween_property(menu_levels, "position", 
				Vector2(get_viewport_rect().size.x, level_pos.y), duration)
			tween.parallel().tween_property(menu_craft, "position", level_pos, duration)
			tween.parallel().tween_property(menu_rewards, "position", 
				Vector2(get_viewport_rect().size.x * 2, reward_pos.y), duration)
			goto_craft.grab_focus()
			
		"rewards":
			tween.tween_property(menu_levels, "position", 
				Vector2(-get_viewport_rect().size.x, level_pos.y), duration)
			tween.parallel().tween_property(menu_craft, "position", 
				Vector2(-get_viewport_rect().size.x * 2, craft_pos.y), duration)
			tween.parallel().tween_property(menu_rewards, "position", level_pos, duration)
			goto_rewards.grab_focus()
	current_menu = target_menu

func _on_levels_pressed() -> void:
	if current_menu != "levels":
		move_menus("levels")

func _on_craft_pressed() -> void:
	if current_menu != "craft":
		move_menus("craft")

func _on_rewards_pressed() -> void:
	if current_menu != "rewards":
		move_menus("rewards")
