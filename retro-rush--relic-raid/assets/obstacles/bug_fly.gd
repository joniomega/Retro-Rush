extends Node2D

@onready var enemy_body := $enemy
@onready var enemy_animation := $enemy/animation

var move_speed := 40  # Adjust speed as needed
var move_direction := 1  # 1 for right, -1 for left
var timer := 0.0
var wait_time := 3.0  # Time in seconds before changing direction

func _ready() -> void:
	# Start by facing right (assuming default sprite faces right)
	enemy_animation.flip_h = false

func _process(delta: float) -> void:
	# Update timer
	timer += delta
	
	# Change direction when timer reaches wait_time
	if timer >= wait_time:
		move_direction *= -1  # Reverse direction
		timer = 0.0  # Reset timer
		
		# Flip animation based on direction
		enemy_animation.flip_h = move_direction < 0
	
	# Move enemy
	position.x += move_speed * move_direction * delta

func _on_damage_area_body_entered(body: Node2D) -> void:
	if body.is_in_group("player"):
		body.die()
	pass # Replace with function body.
