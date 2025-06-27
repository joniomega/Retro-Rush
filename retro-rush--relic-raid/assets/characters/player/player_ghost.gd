# player_ghost.gd
extends CharacterBody2D

const SPEED = 300.0
@export var username = "none"
@export var skin = "1"
@export var accessory = "crest"
var player
var relic
var movement_tween: Tween
var movement_started := false
var x_min := 32.0
var x_max := 160.0
var previous_x: float = 0.0

func _ready():
	username = Global.ranked_opponent_name
	skin = Global.ranked_opponent_skin
	accessory = Global.ranked_opponent_accessory
	$name.text = username
	$AnimatedSprite2D.play(skin + "_ghost")
	$AnimatedSprite2D/accessory.play(accessory + "_jump")
	previous_x = position.x  # Initialize previous position

func _physics_process(delta: float) -> void:
	if player and not movement_started:
		start_movement()
		movement_started = true
		
	# Update sprite flipping based on horizontal movement
	update_sprite_flipping()

func update_sprite_flipping():
	# Calculate horizontal movement direction
	var moving_left = position.x < previous_x
	var moving_right = position.x > previous_x
	
	# Update flip_h properties based on movement
	if moving_left:
		$AnimatedSprite2D.flip_h = true
		$AnimatedSprite2D/accessory.flip_h = true
	elif moving_right:
		$AnimatedSprite2D.flip_h = false
		$AnimatedSprite2D/accessory.flip_h = false
		
	# Store current position for next frame comparison
	previous_x = position.x

func start_movement():
	if movement_tween and movement_tween.is_running():
		movement_tween.kill()
	
	movement_tween = create_tween()
	
	# Safely get player score
	var player_score = 0
	if player and player.has_method("get_score"):
		player_score = player.get_score()
	elif player and "score" in player:
		player_score = player.score
	
	# Determine ghost position relative to player
	var y_offset = -25 if player_score > Global.ranked_opponent_score else 80
	
	# Calculate target position with constraints
	var target_x = randf_range(x_min, x_max)
	var target_y = player.position.y + y_offset + randf_range(-10, 10)
	var target_position = Vector2(target_x, target_y)
	
	# Create irregular movement with random duration
	var move_duration = randf_range(1.4, 1.9)
	
	movement_tween.tween_property(self, "position", target_position, move_duration)
	movement_tween.tween_callback(start_movement)
	$AudioStreamPlayer.play()

func _exit_tree():
	if movement_tween:
		movement_tween.kill()
