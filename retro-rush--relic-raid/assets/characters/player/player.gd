extends CharacterBody2D

var is_on_moving_platform := false  # Add this with other variables
var isdead : bool = false
const SPEED = 80.0
const JUMP_VELOCITY = -350.0
var skill_jump: bool = false
var gravity = ProjectSettings.get_setting("physics/2d/default_gravity")
@export var accessory = Global.player_hat
@export var skin = Global.player_skin

@export var score :int = 0
var displayed_score := 0
@onready var score_label = $Control/CanvasLayer/score
@onready var animation = $AnimatedSprite2D
@onready var anim_accessory = $AnimatedSprite2D/accessory
@onready var camera = $Camera2D
@onready var left_button = $Control/CanvasLayer/left_button
@onready var right_button = $Control/CanvasLayer/right_button
@onready var scrollbar = $Control/CanvasLayer/scrollbar

# Camera will stay locked to this global X position
var camera_lock_x: float
var is_pushing_wall := false
var current_animation := ""
var movement_started := false  # New flag to track if movement has begun

var move_direction := 0  # -1 for left, 1 for right, 0 for no movement
#PAPER FLIP AND SCUASH
var current_tween: Tween = null
var flip_duration := 0.2
var jump_squash_scale := Vector2(1.1, 0.9)
var land_squash_scale := Vector2(0.9, 1.1)

func _ready() -> void:
	if Global.unlocked_levels.size() == 1 && Global.unlocked_levels[0] == 1:
		$Control/CanvasLayer/tutorial.visible = true
		$Control/CanvasLayer/ButtonHome.visible = false
		$Control/CanvasLayer/ButtonHome.disabled = true
		$Control/CanvasLayer/ButtonPause.visible = false
	else:
		$Control/CanvasLayer/tutorial.visible = false
	$Control/CanvasLayer/special_rewards.visible = false
	# Set initial camera lock position (center of screen)
	camera_lock_x = 112
	camera.position.x = 0  # Reset local camera offset
	_play_animation("idle")  # Start idle instead of moving
	velocity.x = 0  # Start with no movement

	# Connect touch buttons to movement functions

func _physics_process(delta: float) -> void:
	if Input.is_action_just_pressed("ui_left"):
		_on_left_button_pressed()
	if Input.is_action_just_pressed("ui_right"):
		_on_right_button_pressed()
	
	if not isdead:
		# Handle jump input
		if skill_jump and Input.is_action_just_pressed("ui_accept") and is_on_floor():
			velocity.y = JUMP_VELOCITY
			_play_animation("jump")

		# Apply gravity
		if not is_on_floor():
			velocity.y += gravity * delta

		# Get platform velocity through collisions
		var platform_velocity = Vector2.ZERO
		if is_on_floor():
			for index in get_slide_collision_count():
				var collision = get_slide_collision(index)
				if collision.get_collider().is_in_group("moving_platform"):
					platform_velocity = collision.get_collider().velocity

		# Calculate movement relative to platform
		var relative_speed = move_direction * SPEED
		if move_direction != 0:
			velocity.x = relative_speed + platform_velocity.x
			is_pushing_wall = (move_direction == 1 and test_move(transform, Vector2.RIGHT * 2)) or \
							(move_direction == -1 and test_move(transform, Vector2.LEFT * 2))
		else:
			velocity.x = platform_velocity.x  # Inherit platform movement only
			is_pushing_wall = false

		# Handle animations
		if is_on_floor():
			if is_pushing_wall:
				_play_animation("idle")
				reset_scale()
			elif abs(relative_speed) > 0:  # Check player input, not total velocity
				_play_animation("walk")
				reset_scale()
				animation.flip_h = move_direction < 0
				anim_accessory.flip_h = move_direction < 0
				
				
			else:
				_play_animation("idle")
				reset_scale()
		else:
			if velocity.y < 0:
				_play_animation("jump")
				animation.flip_h = move_direction < 0
				anim_accessory.flip_h = move_direction < 0
				squash_and_stretch()
			else:
				_play_animation("fall")
				animation.flip_h = move_direction < 0
				anim_accessory.flip_h = move_direction < 0
				squash_and_stretch()

		move_and_slide()

	camera.global_position.x = camera_lock_x

func _play_animation(anim_name: String) -> void:
	if current_animation != anim_name:
		animation.play(skin+"_"+anim_name)
		anim_accessory.play(str(accessory + "_" + anim_name))
		current_animation = anim_name

func scale_sprite():
	var tween = create_tween()
	var original_scale = $AnimatedSprite2D.scale  # Store the current scale
	
	# Scale X down to 0 in 0.15 seconds (Y remains unchanged)
	tween.tween_property($AnimatedSprite2D, "scale", Vector2(0, original_scale.y), 0.1)\
		.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	
	# Scale X back to original in 0.15 seconds (Y remains unchanged)
	tween.tween_property($AnimatedSprite2D, "scale", original_scale, 0.1)\
		.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
func squash_and_stretch() -> void:
	
	if current_tween:
		current_tween.kill()
	
	current_tween = create_tween()
	current_tween.set_trans(Tween.TRANS_BACK)
	current_tween.set_ease(Tween.EASE_OUT)
	
	if not is_on_floor():
		if velocity.y < 0:  # Jumping up
			current_tween.tween_property(animation, "scale", jump_squash_scale, 0.1)
		else:  # Falling down
			current_tween.tween_property(animation, "scale", land_squash_scale, 0.1)
	else:
		current_tween.tween_property(animation, "scale", Vector2(1, 1), 0.2)
func reset_scale() -> void:
	if current_tween:
		current_tween.kill()
	
	current_tween = create_tween()
	current_tween.tween_property(animation, "scale", 
		Vector2(sign(animation.scale.x), 1.0), 0.2)

func shine(increment: int):
	score += increment
	var steps := 20
	var delay := 0.02
	var target := score
	# Light yellow flash
	if increment >=0:
		score_label.modulate = Color(1, 1, 0.5)
	await get_tree().create_timer(0.05).timeout
	for i in range(1, steps + 1):
		if increment >=0:
			$audio_increase.play()
		else:
			$audio_decrease.play()
		var interpolated = lerp(displayed_score, target, i / float(steps))
		score_label.text = str(round(interpolated))
		await get_tree().create_timer(delay).timeout
	
	displayed_score = target
	score_label.modulate = Color(1, 1, 1)  # Back to normal

func die():
	if isdead == true:
		pass
	else:
		isdead = true
		shine(-score)
		$animation.play("die")
		$sound_die.play()
		_play_animation("fall")
		var tree = get_tree()
		await tree.create_timer(1.5).timeout
		TransitionScreen.transition()
		await TransitionScreen.on_transition_finished
		tree.change_scene_to_file("res://scenes/lvl_0.tscn")

# Button press handlers
func _on_left_button_pressed() -> void:
	if isdead == false:
		if move_direction != -1:
			scale_sprite()
		move_direction = -1


func _on_right_button_pressed() -> void:
	if isdead == false:
		if move_direction != 1:
			scale_sprite()
		move_direction = 1

func _on_button_home_pressed() -> void:
	var tree = get_tree()
	TransitionScreen.transition()
	await TransitionScreen.on_transition_finished
	tree.change_scene_to_file("res://menus/mainmenu.tscn")
	pass # Replace with function body.

func win(type:String):
	$Control/CanvasLayer/ButtonHome.disabled = true
	Global.points = Global.points + score
	$Control/CanvasLayer/win/AnimatedSprite2D.play(type)
	isdead = true
	_play_animation("idle")
	$animation.play("win")
	get_parent().stop_music()
	await get_tree().create_timer(3).timeout
	var tree = get_tree()
	TransitionScreen.transition()
	await TransitionScreen.on_transition_finished
	tree.change_scene_to_file("res://menus/mainmenu.tscn")
	pass
func win_special(type:String):
	$Control/CanvasLayer/special_rewards.visible = true
	$Control/CanvasLayer/ButtonHome.disabled = true
	$Control/CanvasLayer/special_rewards.setup_rewards()
	var holo_material = preload("res://assets/shaders/holo.tres")
	#$Control/CanvasLayer/win.material = holo_material
	$Control/CanvasLayer/win/AnimatedSprite2D.material = holo_material
	Global.points = Global.points + score
	$Control/CanvasLayer/win/AnimatedSprite2D.play(type)
	isdead = true
	_play_animation("idle")
	$animation.play("win_special")
	get_parent().stop_music()
	pass
func win_ranked(type:String):
	
	if score >= Global.ranked_opponent_score:
		# Existing visual effects code...
		$Control/CanvasLayer/special_rewards.visible = true
		$Control/CanvasLayer/ButtonHome.disabled = true
		$Control/CanvasLayer/special_rewards.setup_rewards()
		var holo_material = preload("res://assets/shaders/holo.tres")
		$Control/CanvasLayer/win/AnimatedSprite2D.material = holo_material
		Global.points = Global.points + score
		$Control/CanvasLayer/win/AnimatedSprite2D.play(type)
		isdead = true
		_play_animation("idle")
		$animation.play("win_special")
		get_parent().stop_music()
		
		if Global.firebase_id == "":
			push_error("No Firebase ID - cannot update records")
			return
		
		# First get all current data
		var http_request = HTTPRequest.new()
		add_child(http_request)
		http_request.request_completed.connect(_on_get_data_completed.bind(http_request))
		
		var url = "https://retrorush-descend-default-rtdb.europe-west1.firebasedatabase.app/leaderboard/%s.json" % Global.firebase_id
		var error = http_request.request(url)
		if error != OK:
			push_error("Failed to request player data")
			http_request.queue_free()
	else:
		die_ranked()

func _on_get_data_completed(result, response_code, headers, body, http_request):
	http_request.queue_free()
	
	if result != HTTPRequest.RESULT_SUCCESS or response_code != 200:
		push_error("Failed to get player data - Status: %d" % response_code)
		return
	
	var player_data = JSON.parse_string(body.get_string_from_utf8())
	if player_data == null:
		player_data = {}
	
	# Get current wins (default to 0 if not exists)
	var current_wins = player_data.get("wins", 0)
	print("Current wins from Firebase:", current_wins)  # Debug print
	
	# Get current scores (initialize if not exists)
	var scores = player_data.get("score", {"lvl1": 0, "lvl2": 0, "lvl3": 0})
	
	# Only update score if new score is higher
	var current_level_key = "lvl%d" % Global.ranked_level
	var current_level_score = scores.get(current_level_key, 0)
	var should_update_score = score > current_level_score
	
	# Prepare updates
	var updates = {}
	
	# Update wins (always increment)
	updates["wins"] = current_wins + 1
	
	# Update score only if higher
	if should_update_score:
		updates["score/%s" % current_level_key] = score
		print("Updating level %d score from %d to %d" % [Global.ranked_level, current_level_score, score])
	else:
		print("Keeping existing level %d score of %d (new score %d was lower)" % [Global.ranked_level, current_level_score, score])
	
	# Send updates
	var update_request = HTTPRequest.new()
	add_child(update_request)
	update_request.request_completed.connect(_on_update_completed.bind(update_request))
	
	var url = "https://retrorush-descend-default-rtdb.europe-west1.firebasedatabase.app/leaderboard/%s.json" % Global.firebase_id
	headers = ["Content-Type: application/json"]
	var error = update_request.request(url, headers, HTTPClient.METHOD_PATCH, JSON.stringify(updates))
	
	if error != OK:
		push_error("Failed to send update request")
		update_request.queue_free()

func _on_update_completed(result, response_code, headers, body, http_request):
	http_request.queue_free()
	
	if result == HTTPRequest.RESULT_SUCCESS and response_code == 200:
		print("Successfully updated Firebase records")
		var updated_data = JSON.parse_string(body.get_string_from_utf8())
		print("New wins count:", updated_data.get("wins", 1))
	else:
		push_error("Update failed - Status: %d" % response_code)
		if body:
			print("Error response:", body.get_string_from_utf8())
func die_ranked():
	if isdead == true:
		pass
	else:
		isdead = true
		shine(-score)
		$animation.play("die")
		$sound_die.play()
		_play_animation("fall")
		$animation.play("win")
		$Control/CanvasLayer/win/AnimatedSprite2D.visible = false
		$Control/CanvasLayer/win.text = "[wave][center][color=#cc1d00][b]YOU          LOST[/b][/color][/center][/wave]"
		$Control/CanvasLayer/win/rankedwin.visible = true
		$Control/CanvasLayer/win/rankedwin.text = str("[wave][center]"+Global.ranked_opponent_name+">"+Global.player_name+"[wave][center]")
		
		var tree = get_tree()
		await tree.create_timer(3.5).timeout
		TransitionScreen.transition()
		await TransitionScreen.on_transition_finished
		tree.change_scene_to_file("res://menus/mainmenu.tscn")
