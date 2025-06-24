extends Control

@export var level_num : int = 0
var global
@onready var button = $Button
var http_request: HTTPRequest
var opponent_data: Dictionary
var selected_level_score: int
var is_requesting: bool = false

func _ready() -> void:
	global = Global
	http_request = HTTPRequest.new()
	add_child(http_request)
	http_request.request_completed.connect(_on_http_request_completed)
	

func _on_button_pressed() -> void:
	if not is_requesting:
		fetch_random_opponent()
	else:
		print("Request already in progress")

func fetch_random_opponent():
	var url = "https://retrorush-descend-default-rtdb.europe-west1.firebasedatabase.app/leaderboard.json"
	is_requesting = true
	var error = http_request.request(url)
	if error != OK:
		is_requesting = false
		push_error("Failed to request leaderboard data")

func _on_http_request_completed(result, response_code, headers, body):
	is_requesting = false
	
	if result != HTTPRequest.RESULT_SUCCESS:
		push_error("Request failed with result: " + str(result))
		return
	
	if response_code != 200:
		push_error("HTTP error: " + str(response_code))
		return
	
	var json = JSON.new()
	var parse_error = json.parse(body.get_string_from_utf8())
	
	if parse_error != OK:
		push_error("JSON parse error: " + str(parse_error))
		return
	
	var data = json.get_data()
	if typeof(data) != TYPE_DICTIONARY:
		push_error("Invalid data format")
		return
	
	# Filter out players with score data
	var valid_players = []
	for player_id in data:
		var player = data[player_id]
		if typeof(player) == TYPE_DICTIONARY and player.has("score"):
			valid_players.append(player)
	
	if valid_players.size() == 0:
		push_error("No players with score data found")
		return
	
	# Select random opponent
	opponent_data = valid_players[randi() % valid_players.size()]
	start_ranked_match()

func start_ranked_match():
	# Select random level (1-3)
	var level = randi_range(1, 3)
	var score_key = "lvl%d" % level
	selected_level_score = opponent_data["score"].get(score_key, 300)
	
	# Set global variables for the ranked match
	Global.ranked_opponent_name = opponent_data["name"]
	Global.ranked_opponent_score = selected_level_score
	Global.ranked_level = level
	Global.selected_level_special = false
	
	# Random biome material
	var materials = [
		preload("res://assets/shaders/backmaterial_1.tres"),
		preload("res://assets/shaders/backmaterial_2.tres"),
		preload("res://assets/shaders/backmaterial_3.tres"),
		preload("res://assets/shaders/backmaterial_4.tres"),
		preload("res://assets/shaders/backmaterial_5.tres"),
		preload("res://assets/shaders/backmaterial_special.tres")
	]
	Global.ranked_biome_material = materials[randi() % materials.size()]
	
	# Transition to ranked level
	TransitionScreen.transition()
	await TransitionScreen.on_transition_finished
	get_tree().change_scene_to_file("res://scenes/lvl_ranked.tscn")
func disable():
	$Button.text = "Create name or check internet"
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
