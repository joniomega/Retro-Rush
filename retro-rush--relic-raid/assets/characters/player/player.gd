extends CharacterBody2D

var isdead : bool = false
const SPEED = 80.0
const JUMP_VELOCITY = -350.0
var skill_jump: bool = false
var gravity = ProjectSettings.get_setting("physics/2d/default_gravity")
@export var accessory = "none"

@export var score :int = 0
var displayed_score := 0
@onready var score_label = $Control/CanvasLayer/score
@onready var animation = $AnimatedSprite2D
@onready var anim_accessory = $AnimatedSprite2D/accessory
@onready var camera = $Camera2D
@onready var left_button = $Control/CanvasLayer/left_button
@onready var right_button = $Control/CanvasLayer/right_button

# Camera will stay locked to this global X position
var camera_lock_x: float
var is_pushing_wall := false
var current_animation := ""
var movement_started := false  # New flag to track if movement has begun

var move_direction := 0  # -1 for left, 1 for right, 0 for no movement

func _ready() -> void:
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

		# Apply horizontal movement based on direction
		if move_direction != 0:
			if not movement_started:
				movement_started = true
			velocity.x = move_direction * SPEED
			is_pushing_wall = (move_direction == 1 and test_move(transform, Vector2.RIGHT * 2)) or \
							  (move_direction == -1 and test_move(transform, Vector2.LEFT * 2))
		else:
			is_pushing_wall = false
			velocity.x = 0

		# Handle animations
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
		anim_accessory.play(str(accessory + "_" + anim_name))
		current_animation = anim_name

func shine(increment: int):
	score += increment
	var steps := 20
	var delay := 0.02
	var target := score
	score_label.modulate = Color(1, 1, 0.5)  # Light yellow flash
	await get_tree().create_timer(0.05).timeout
	for i in range(1, steps + 1):
		var interpolated = lerp(displayed_score, target, i / float(steps))
		score_label.text = str(round(interpolated))
		await get_tree().create_timer(delay).timeout
	
	displayed_score = target
	score_label.modulate = Color(1, 1, 1)  # Back to normal

func die():
	isdead = true
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
	move_direction = -1

func _on_right_button_pressed() -> void:
	move_direction = 1


func _on_button_home_pressed() -> void:
	var tree = get_tree()
	TransitionScreen.transition()
	await TransitionScreen.on_transition_finished
	tree.change_scene_to_file("res://menus/mainmenu.tscn")
	pass # Replace with function body.

func win(type:String):
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
