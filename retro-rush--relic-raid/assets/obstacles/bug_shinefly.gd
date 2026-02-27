extends CharacterBody2D

@onready var animation := $animation
@onready var collision_shape := $CollisionShape2D
@onready var particles := $CPUParticles2D

var move_speed := 30
var move_direction := 1
var timer := 0.0
var wait_time := 3.0
var gravity = ProjectSettings.get_setting("physics/2d/default_gravity")
var is_alive := true

# New variables for vertical movement
var vertical_amplitude := 10  # How far up/down to move
var vertical_speed := 2.0     # Speed of vertical oscillation
var vertical_offset := 0.0    # Current vertical position offset
var vertical_direction := 1    # Current vertical direction (1 for up, -1 for down)
var vertical_timer := 0.0      # Timer for vertical movement changes

func _ready() -> void:
	# Play random wait and speed
	var waitvars = [2, 3, 4]
	wait_time = (waitvars[randi() % waitvars.size()])
	# Play random fly animation
	animation.flip_h = false
	
	# Random starting vertical direction
	vertical_direction = 1 if randi() % 2 == 0 else -1

func _physics_process(delta: float) -> void:
	if !is_alive:
		velocity.y += gravity * delta
		move_and_slide()
		return

	# Alive movement
	timer += delta
	if timer >= wait_time:
		scale_sprite()
		move_direction *= -1
		timer = 0.0
		animation.flip_h = move_direction < 0
	
	# Horizontal movement
	velocity.x = move_speed * move_direction
	
	# Vertical zigzag movement
	vertical_timer += delta
	
	# Change vertical direction randomly every 0.5-1.5 seconds
	if vertical_timer >= randf_range(0.5, 1.5):
		vertical_direction *= -1
		vertical_timer = 0.0
	
	# Apply vertical movement
	velocity.y = vertical_speed * vertical_direction * vertical_amplitude
	
	move_and_slide()

func scale_sprite():
	var tween = create_tween()
	var original_scale = $animation.scale  # Store the current scale
	
	# Scale X down to 0 in 0.15 seconds (Y remains unchanged)
	tween.tween_property($animation, "scale", Vector2(0, original_scale.y), 0.1)\
		.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	
	# Scale X back to original in 0.15 seconds (Y remains unchanged)
	tween.tween_property($animation, "scale", original_scale, 0.1)\
		.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)

func die():
	if !is_alive:
		return
	is_alive = false
	animation.play("dead")
	$ColorRect.visible= false
	$normal.emitting = false
	$explode.emitting = true
	particles.emitting = true
	$sound_break.play()
	velocity = Vector2(0, 0)

func _on_damage_area_body_entered(body: Node2D) -> void:
	if body.is_in_group("player"):
		body.velocity.y = -200
		body.shine(25)
		die()
		$damage_area.queue_free()
