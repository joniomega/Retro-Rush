extends CharacterBody2D

var isdead : bool = false
const SPEED = 80.0
const JUMP_VELOCITY = -350.0
var skill_jump: bool = false
var gravity = ProjectSettings.get_setting("physics/2d/default_gravity")

@export var score :int = 0
var displayed_score := 0
@onready var score_label = $Control/CanvasLayer/score
@onready var animation = $AnimatedSprite2D
@onready var anim_accessory = $AnimatedSprite2D/accessory
@onready var camera = $Camera2D

# Camera will stay locked to this global X position
var camera_lock_x: float
var auto_moving_right := true
var is_pushing_wall := false
var current_animation := ""
var movement_started := false  # New flag to track if movement has begun

func _ready() -> void:
	# Set initial camera lock position (center of screen)
	camera_lock_x = 112
	camera.position.x = 0  # Reset local camera offset
	_play_animation("idle")  # Start idle instead of moving
	velocity.x = 0  # Start with no movement

func _physics_process(delta: float) -> void:
	if isdead == false:
		# Handle jump input
		if skill_jump == true:
			if Input.is_action_just_pressed("ui_accept") and is_on_floor():
				velocity.y = JUMP_VELOCITY
				_play_animation("jump")
		# Apply gravity
		if not is_on_floor():
			velocity.y += gravity * delta
		# Check for wall collision in current movement direction
		is_pushing_wall = (auto_moving_right and test_move(transform, Vector2.RIGHT * 2)) or \
						 (not auto_moving_right and test_move(transform, Vector2.LEFT * 2))
		# Handle direction changes
		var direction := Input.get_axis("ui_left", "ui_right")
		if direction != 0:
			if not movement_started:  # First input starts movement
				movement_started = true
				auto_moving_right = (direction > 0)
			velocity.x = direction * SPEED
			is_pushing_wall = false
			auto_moving_right = (direction > 0)  # Update direction with each input
		# Automatic movement when no input (only after movement has started)
		elif movement_started and not is_pushing_wall:
			velocity.x = SPEED if auto_moving_right else -SPEED
		else:
			velocity.x = 0
		# Handle animations based on state
		if is_on_floor():
			if is_pushing_wall:
				_play_animation("idle")
			elif velocity.x != 0:
				_play_animation("walk")
				animation.flip_h = velocity.x < 0
			else:
				_play_animation("idle")
		else:
			if velocity.y < 0:
				_play_animation("jump")
			else:
				_play_animation("fall")
		move_and_slide()
	camera.global_position.x = camera_lock_x

func _play_animation(anim_name: String) -> void:
	if current_animation != anim_name:
		animation.play(anim_name)
		anim_accessory.play(anim_name)
		current_animation = anim_name


func shine():
	var increment := 25
	score += increment
	
	var steps := 20
	var delay := 0.02
	var target := score
	
	# Scale pop effect
	#score_label.scale = Vector2(1.5, 1.5)
	score_label.modulate = Color(1, 1, 0.5) # Light yellow flash
	
	await get_tree().create_timer(0.05).timeout
	
	# Animate the number like a typewriter
	for i in range(1, steps + 1):
		var interpolated = lerp(displayed_score, target, i / float(steps))
		score_label.text = str(round(interpolated))
		await get_tree().create_timer(delay).timeout
	
	displayed_score = target
	
	# Restore label effects
	#score_label.scale = Vector2(1, 1)
	score_label.modulate = Color(1, 1, 1) # Back to normal

func die():
	isdead = true
	$animation.play("die")
	_play_animation("idle")
	var tree = get_tree()  # Capture SceneTree reference while still in the tree
	await tree.create_timer(1.5).timeout
	TransitionScreen.transition()
	await TransitionScreen.on_transition_finished
	tree.change_scene_to_file("res://scenes/lvl_0.tscn")  # Use captured reference
