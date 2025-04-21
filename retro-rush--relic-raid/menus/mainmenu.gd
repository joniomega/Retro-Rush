extends Node2D


# Called when the node enters the scene tree for the first time.
var global = Global 
func _ready() -> void:
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass


func _on_lvl_1_pressed() -> void:
	global.selected_level = 1
	var tree = get_tree()
	TransitionScreen.transition()
	await TransitionScreen.on_transition_finished
	tree.change_scene_to_file("res://scenes/lvl_0.tscn")
	pass # Replace with function body.


func _on_lvl_2_pressed() -> void:
	global.selected_level = 2
	var tree = get_tree()
	TransitionScreen.transition()
	await TransitionScreen.on_transition_finished
	tree.change_scene_to_file("res://scenes/lvl_0.tscn")
	pass # Replace with function body.
