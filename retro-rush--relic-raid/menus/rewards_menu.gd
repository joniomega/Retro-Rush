extends Control

@onready var wheel_sprite2d = $Wheel
@onready var label = $Label
@onready var spin_button = $Button

const REWARD_ANGLES := {
	"string": [0, -360],
	"leather": [-90, 270],
	"flower": [180, -180],
	"moss": [-270, 90]
}
var is_spinning := false

func _on_button_pressed() -> void:
	if !is_spinning:
		spin_wheel()

func spin_wheel():
	is_spinning = true
	spin_button.disabled = true
	$ppriest.play("spin")
	label.text = "Spinning..."
	
	# Randomly select a reward (all have equal chance)
	var rewards = REWARD_ANGLES.keys()
	var selected_reward = rewards[randi() % rewards.size()]
	var target_angle = REWARD_ANGLES[selected_reward][0]
	
	# Spin parameters
	var full_spins = 4  # Number of full rotations before stopping
	var spin_duration = 3.0  # Seconds
	
	# Normalize current rotation to 0-360 range
	var current_rotation = fmod(wheel_sprite2d.rotation_degrees, 360)
	
	# Calculate total rotation needed (full spins + angle to target)
	var total_rotation = full_spins * 360 + (360 - current_rotation) + target_angle
	
	# Create tween for smooth spinning
	var tween = create_tween()
	tween.tween_property(wheel_sprite2d, "rotation_degrees", 
						wheel_sprite2d.rotation_degrees + total_rotation, 
						spin_duration)\
		 .set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_QUAD)
	
	# When spin completes
	tween.tween_callback(func(): 
		# Snap to exact target angle
		wheel_sprite2d.rotation_degrees = target_angle
		$ppriest.play("normal")
		label.text = "Winner: " + selected_reward
		is_spinning = false
		spin_button.disabled = false
	)
