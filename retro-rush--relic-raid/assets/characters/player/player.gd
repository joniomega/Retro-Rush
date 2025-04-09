extends CharacterBody2D

const SPEED = 80.0
const JUMP_VELOCITY = -500.0
var gravity = ProjectSettings.get_setting("physics/2d/default_gravity")

@onready var animation = $AnimatedSprite2D
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
	# Handle jump input
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
		current_animation = anim_name
