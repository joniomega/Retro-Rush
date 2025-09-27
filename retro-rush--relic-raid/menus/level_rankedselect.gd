extends Control

@export var level_num : int = 0
var global
@onready var button = $Button

func _ready() -> void:
	pass

func _on_button_pressed() -> void:
	var tree = get_tree()
	TransitionScreen.transition()
	await TransitionScreen.on_transition_finished
	tree.change_scene_to_file("res://scenes/lvl_infinite.tscn")
	pass

func disable():
	$Button.text = "Create name"
	$Label.visible = false
	$AnimatedSprite2D.visible = false
	$Button.disabled = true
	$CPUParticles2D2.emitting = false
	pass
func enable():
	$Button.text = ""
	$Label.visible = true
	$AnimatedSprite2D.visible = true
	$Button.disabled = false
	$CPUParticles2D2.emitting = true
	pass
	pass
