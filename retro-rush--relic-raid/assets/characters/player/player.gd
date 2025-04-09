extends CharacterBody2D

const SPEED = 150.0
const JUMP_VELOCITY = -500.0
var gravity = ProjectSettings.get_setting("physics/2d/default_gravity")

@onready var animation = $AnimatedSprite2D
@onready var camera = $Camera2D

# Camera will stay locked to this global X position
var camera_lock_x: float

func _ready() -> void:
	# Set initial camera lock position (center of screen)
	camera_lock_x = 112
	camera.position.x = 0  # Reset local camera offset

func _physics_process(delta: float) -> void:
	# Apply gravity properly (as Vector2)
	if not is_on_floor():
		velocity.y += gravity * delta

	# Handle jump
	if Input.is_action_just_pressed("ui_accept") and is_on_floor():
		velocity.y = JUMP_VELOCITY

	# Horizontal movement
	var direction := Input.get_axis("ui_left", "ui_right")
	if direction:
		velocity.x = direction * SPEED
		animation.play("right" if direction > 0 else "left")
	else:
		velocity.x = move_toward(velocity.x, 0, SPEED)
		animation.play("idle")  # Make sure you have this animation

	move_and_slide()
	
	# Lock camera horizontally while following vertically
	camera.global_position.x = camera_lock_x
