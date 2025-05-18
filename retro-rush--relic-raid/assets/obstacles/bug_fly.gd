extends CharacterBody2D

@onready var animation := $animation
@onready var collision_shape := $CollisionShape2D
@onready var particles := $CPUParticles2D

var move_speed := 40
var move_direction := 1
var timer := 0.0
var wait_time := 3.0
var gravity = ProjectSettings.get_setting("physics/2d/default_gravity")
var is_alive := true

func _ready() -> void:
	# Play random wait and speed
	var waitvars = [2, 3, 4]
	wait_time = (waitvars[randi() % waitvars.size()])
	var speedvars = [30, 40, 45]
	move_speed = (speedvars[randi() % speedvars.size()])
	# Play random fly animation
	var fly_animations = ["fly1", "fly2", "fly3"]
	animation.play(fly_animations[randi() % fly_animations.size()])
	animation.flip_h = false

func _physics_process(delta: float) -> void:
	if !is_alive:
		velocity.y += gravity * delta
		move_and_slide()
		return

	# Alive movement
	timer += delta
	if timer >= wait_time:
		move_direction *= -1
		timer = 0.0
		animation.flip_h = move_direction < 0
		scale_sprite()
	
	velocity.x = move_speed * move_direction
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
	particles.emitting = true
	$sound_break.play()
	velocity = Vector2(0, 0)

func _on_damage_area_body_entered(body: Node2D) -> void:
	if body.is_in_group("player"):
		body.velocity.y = -200
		body.shine(10)
		die()
		$damage_area.queue_free()
