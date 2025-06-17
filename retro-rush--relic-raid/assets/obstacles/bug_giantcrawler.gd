extends Node2D

var lives = 4
var started : bool = false
var can_take_damage : bool = true
var eye_active := [true, true, true, true]  # Track which eyes are still open
var is_dead = false
var is_tongue_attacking: bool = false

# Track which side is currently vulnerable: "both", "left" or "right"
var current_vulnerable_side : String = "both"

@onready var giantcrawler     = $giantcrawler
@onready var tongue           = $giantcrawler/tonge
@onready var leftfrontleg     = $giantcrawler/legfrontleft
@onready var rightfrontleg    = $giantcrawler/legfrontright
@onready var leftbackleg      = $giantcrawler/legbackleft
@onready var rightbackleg     = $giantcrawler/legbackright

# For easy access to each eye node
@onready var eyes = {
	0: $giantcrawler/eye1,
	1: $giantcrawler/eye2,
	2: $giantcrawler/eye3,
	3: $giantcrawler/eye4,
}

# Movement variables
var is_moving_up: bool = false
var body_offset: float = 30.0
var leg_rotation_angle: float = 20.0
var original_position: Vector2
var movement_speed: float = 1.0
var leg_movement_speed: float = 0.4
var tongue_speed: float = 1.6

func _ready() -> void:
	original_position = giantcrawler.position
	play_eyes_open()
	update_eye_open_states()  # enforce initial vulnerability

func start_movement():
	move_body()

func move_body():
	if is_dead:
		return
	var t = create_tween()
	var ty = original_position.y - body_offset if not is_moving_up else original_position.y
	t.tween_property(giantcrawler, "position:y", ty, movement_speed).set_ease(Tween.EASE_IN_OUT).set_trans(Tween.TRANS_SINE)
	animate_legs()
	is_moving_up = not is_moving_up
	t.tween_interval(0.8)
	t.tween_callback(move_body)

func animate_legs():
	if is_dead:
		return
	var t = create_tween()
	t.tween_property(leftfrontleg, "rotation_degrees", -leg_rotation_angle if is_moving_up else leg_rotation_angle, leg_movement_speed)
	t.parallel().tween_property(rightfrontleg, "rotation_degrees", leg_rotation_angle if is_moving_up else -leg_rotation_angle, leg_movement_speed)
	t.tween_interval(0.2)
	t.tween_property(leftbackleg, "rotation_degrees", leg_rotation_angle if is_moving_up else -leg_rotation_angle, leg_movement_speed)
	t.parallel().tween_property(rightbackleg, "rotation_degrees", -leg_rotation_angle if is_moving_up else leg_rotation_angle, leg_movement_speed)
	t.tween_interval(0.3)
	t.tween_property(leftfrontleg, "rotation_degrees", 0, leg_movement_speed)
	t.parallel().tween_property(rightfrontleg, "rotation_degrees", 0, leg_movement_speed)
	t.parallel().tween_property(leftbackleg, "rotation_degrees", 0, leg_movement_speed)
	t.parallel().tween_property(rightbackleg, "rotation_degrees", 0, leg_movement_speed)

func attack_with_tongue():
	if is_dead or is_tongue_attacking:
		return
	is_tongue_attacking = true
	giantcrawler.play("openmouth")
	var t = create_tween()
	t.tween_property(tongue, "position:y", tongue.position.y - 40, tongue_speed).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_BACK)
	t.tween_interval(1.0)
	t.tween_property(tongue, "position:y", tongue.position.y, tongue_speed).set_ease(Tween.EASE_IN)
	t.tween_callback(func():
		if not is_dead: giantcrawler.play("closemouth")
		is_tongue_attacking = false
	)

func dead():
	$giantcrawler/moutharea.queue_free()
	$giantcrawler/tonge.queue_free()
	$giantcrawler/bodyarea.queue_free()
	is_dead = true
	$giantcrawler/CPUParticles2D.emitting = true
	var t = create_tween()
	t.tween_property(giantcrawler, "modulate:a", 0.0, 1.0)
	t.tween_callback(func():
		if is_instance_valid(giantcrawler):
			await get_tree().create_timer(3.5).timeout
			giantcrawler.queue_free()
	)

func start_damage_cooldown():
	can_take_damage = false
	for i in range(4):
		if eye_active[i] and is_instance_valid(eyes[i]):
			eyes[i].play("closed")
	await get_tree().create_timer(2.5).timeout
	can_take_damage = true
	update_eye_open_states()

func handle_eye_hit(eye_index: int, body: Node2D):
	if is_dead or not can_take_damage or not eye_active[eye_index]:
		return
	var side = "left" if eye_index <= 1 else "right"
	if current_vulnerable_side != "both" and side != current_vulnerable_side:
		return

	body.velocity.y = -300
	eye_active[eye_index] = false
	if is_instance_valid(eyes[eye_index]):
		eyes[eye_index].queue_free()

	# Change side vulnerability
	current_vulnerable_side = "right" if side == "left" else "left"
	update_eye_open_states()

	lives -= 1
	body.shine(50)
	$AudioStreamPlayer_hurt.play()
	if lives == 0:
		dead()
	else:
		var t = create_tween()
		t.tween_property(self, "position", position + Vector2(5, 0), 0.05)
		t.tween_property(self, "position", position + Vector2(-5, 0), 0.05)
		t.tween_property(self, "position", position + Vector2(3, 0), 0.05)
		t.tween_property(self, "position", position + Vector2(-3, 0), 0.05)
		t.tween_property(self, "position", position, 0.05)
		start_damage_cooldown()

func update_eye_open_states():
	for i in range(4):
		if eye_active[i] and is_instance_valid(eyes[i]):
			var side = "left" if i <= 1 else "right"
			if current_vulnerable_side == "both" or side == current_vulnerable_side:
				eyes[i].play("open")
			else:
				eyes[i].play("closed")

func play_eyes_open():
	for i in range(4):
		if eye_active[i] and is_instance_valid(eyes[i]):
			eyes[i].play("open")

func _on_eyearea_1_body_entered(body: Node2D) -> void:
	if body.is_in_group("player"):
		handle_eye_hit(0, body)

func _on_eyearea_2_body_entered(body: Node2D) -> void:
	if body.is_in_group("player"):
		handle_eye_hit(1, body)

func _on_eyearea_3_body_entered(body: Node2D) -> void:
	if body.is_in_group("player"):
		handle_eye_hit(2, body)

func _on_eyearea_4_body_entered(body: Node2D) -> void:
	if body.is_in_group("player"):
		handle_eye_hit(3, body)

func _on_tongearea_body_entered(body: Node2D) -> void:
	if body.is_in_group("player"):
		body.die()

func _on_moutharea_body_entered(body: Node2D) -> void:
	if body.is_in_group("player"):
		body.die()

func _on_bodyarea_body_entered(body: Node2D) -> void:
	if body.is_in_group("player"):
		body.velocity.y = -300

func _on_enterarea_body_entered(body: Node2D) -> void:
	if is_dead or started:
		return
	if body.is_in_group("player"):
		started = true
		$AudioStreamPlayer_scream.play()
		var t = create_tween()
		t.tween_property(self, "position", position + Vector2(5,0), 0.05)
		t.tween_property(self, "position", position + Vector2(-5,0), 0.05)
		t.tween_property(self, "position", position + Vector2(3,0), 0.05)
		t.tween_property(self, "position", position + Vector2(-3,0), 0.05)
		t.tween_property(self, "position", position, 0.05)
		start_movement()
		$tonguetimer.start()

func _on_tonguetimer_timeout() -> void:
	attack_with_tongue()
	$tonguetimer.start()
