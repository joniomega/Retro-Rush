extends Control

@onready var name_labels = [
	$GridContainer/pos1/name,
	$GridContainer/pos2/name,
	$GridContainer/pos3/name
]

@onready var win_labels = [
	$GridContainer/pos1/wins,
	$GridContainer/pos2/wins,
	$GridContainer/pos3/wins
]

@onready var skin_animatedsprites = [
	$GridContainer/pos1/skin,
	$GridContainer/pos2/skin,
	$GridContainer/pos3/skin
]

@onready var accessory_animatedsprites = [
	$GridContainer/pos1/skin/accessory,
	$GridContainer/pos2/skin/accessory,
	$GridContainer/pos3/skin/accessory
]

@onready var textedit_name = $GridContainer/config/TextEdit
@onready var playerwins_label = $GridContainer/config/playerwins_label
@onready var grid_container = $GridContainer
@onready var level_rankedselect = $level_rankedselect

var is_online: bool = false
var has_player_name: bool = false
var connectivity_check_timer: Timer

var http_request: HTTPRequest  # For player operations
var http_request_leaderboard: HTTPRequest  # For leaderboard operations
var is_creating_player: bool = false

func _ready():
	Global.ranked_opponent_name = "none"
	Global.ranked_opponent_score = 0
	if Global.player_name != "":
		textedit_name.text = Global.player_name
		has_player_name = true
	
	# Create HTTP request for player operations
	http_request = HTTPRequest.new()
	add_child(http_request)
	http_request.request_completed.connect(_on_player_request_completed)
	
	# Create separate HTTP request for leaderboard
	http_request_leaderboard = HTTPRequest.new()
	add_child(http_request_leaderboard)
	http_request_leaderboard.request_completed.connect(_on_leaderboard_request_completed)
	
	# Set up connectivity checking
	connectivity_check_timer = Timer.new()
	add_child(connectivity_check_timer)
	connectivity_check_timer.timeout.connect(_check_internet_connectivity)
	connectivity_check_timer.start(5.0)  # Check every 5 seconds
	
	# Initial check
	_check_internet_connectivity()
	update_ui_state()

func _check_internet_connectivity():
	var http_request = HTTPRequest.new()
	http_request.timeout = 3  # Set timeout to 3 seconds
	add_child(http_request)
	http_request.request_completed.connect(_on_connectivity_check_completed.bind(http_request))
	
	var error = http_request.request("https://www.google.com/favicon.ico")
	if error != OK:
		http_request.queue_free()
		_handle_internet_status(false)

func _on_connectivity_check_completed(result, response_code, headers, body, http_request_node):
	http_request_node.queue_free()
	_handle_internet_status(result == HTTPRequest.RESULT_SUCCESS and response_code == 200)

func _handle_internet_status(connected: bool):
	if is_online != connected:
		is_online = connected
		if is_online:
			print("Internet connection restored")
			fetch_leaderboard()
		else:
			print("Internet connection lost")
			playerwins_label.text = "Offline"
		update_ui_state()

func update_ui_state():
	grid_container.visible = is_online
	update_rankedselect_state()

func fetch_leaderboard():
	if !is_online:
		update_ui_state()
		return
	
	var url = "https://retrorush-descend-default-rtdb.europe-west1.firebasedatabase.app/leaderboard.json"
	var error = http_request_leaderboard.request(url)
	
	if error != OK:
		push_error("HTTP request error: " + str(error))
		show_placeholder_data()

func _on_save_pressed() -> void:
	var new_name = textedit_name.text.strip_edges()
	if new_name == "":
		has_player_name = false
		update_rankedselect_state()
		return
	
	has_player_name = true
	var current_id = Global.firebase_id
	Global.player_name = new_name
	
	if Global.firebase_id == "":
		is_creating_player = true
		submit_new_player(new_name)
	else:
		update_existing_player(current_id, new_name)
	
	update_rankedselect_state()

func update_rankedselect_state():
	if is_online && has_player_name:
		level_rankedselect.enable()
	else:
		level_rankedselect.disable()

func submit_new_player(name: String):
	var url = "https://retrorush-descend-default-rtdb.europe-west1.firebasedatabase.app/leaderboard.json"
	var headers = ["Content-Type: application/json"]
	var body = JSON.stringify({
		"name": name,
		"wins": 0,
		"skin": Global.player_skin.to_int(),
		"accessory": Global.player_hat
	})
	
	var error = http_request.request(url, headers, HTTPClient.METHOD_POST, body)
	if error != OK:
		push_error("Failed to submit new player")

func update_existing_player(player_id: String, new_name: String):
	if player_id == "":
		return
	
	var url = "https://retrorush-descend-default-rtdb.europe-west1.firebasedatabase.app/leaderboard/%s.json" % player_id
	var headers = ["Content-Type: application/json"]
	var body = JSON.stringify({
		"name": new_name,
		"skin": Global.player_skin.to_int(),
		"accessory": Global.player_hat
	})
	
	var error = http_request.request(url, headers, HTTPClient.METHOD_PATCH, body)
	if error != OK:
		push_error("Failed to update player data")

func _on_player_request_completed(result, response_code, headers, body):
	if result != HTTPRequest.RESULT_SUCCESS:
		print("Player request failed. Result: " + str(result))
		return
	
	if response_code != 200:
		var response_body = body.get_string_from_utf8()
		push_error("HTTP error " + str(response_code) + ": " + response_body)
		return
	
	var json = JSON.new()
	var parse_error = json.parse(body.get_string_from_utf8())
	
	if parse_error != OK:
		push_error("JSON parse error: " + str(parse_error))
		return
	
	var data = json.get_data()
	
	if data == null:
		return
		
	if is_creating_player and typeof(data) == TYPE_DICTIONARY and data.has("name"):
		Global.firebase_id = data.name
		Global.save_progress()
		is_creating_player = false
		playerwins_label.text = "0"
	
	fetch_leaderboard()

func _on_leaderboard_request_completed(result, response_code, headers, body):
	if result != HTTPRequest.RESULT_SUCCESS:
		print("Leaderboard request failed. Result: " + str(result))
		show_placeholder_data()
		return
	
	if response_code != 200:
		var response_body = body.get_string_from_utf8()
		push_error("HTTP error " + str(response_code) + ": " + response_body)
		show_placeholder_data()
		return
	
	var json = JSON.new()
	var parse_error = json.parse(body.get_string_from_utf8())
	
	if parse_error != OK:
		push_error("JSON parse error: " + str(parse_error))
		show_placeholder_data()
		return
	
	var data = json.get_data()
	
	if data == null:
		show_placeholder_data()
		return
		
	update_scoreboard(data)

func update_scoreboard(data):
	if typeof(data) != TYPE_DICTIONARY or data.is_empty():
		show_placeholder_data()
		return
	
	var scores = []
	for key in data:
		var entry = data[key]
		if typeof(entry) == TYPE_DICTIONARY:
			entry["firebase_id"] = key
			scores.append(entry)
	
	if scores.size() == 0:
		show_placeholder_data()
		return
	
	scores.sort_custom(func(a, b): 
		var wins_a = a.get("wins", 0)
		var wins_b = b.get("wins", 0)
		return wins_a > wins_b
	)
	
	var top_scores = scores.slice(0, min(3, scores.size()))
	
	for i in range(min(3, top_scores.size())):
		var score = top_scores[i]
		name_labels[i].text = str(score.get("name", "Player"))
		win_labels[i].text = str(int(score.get("wins", 0))) + "w"
		
		if "skin" in score:
			var intskin:int = int(score.skin) 
			var skin_animation = str(intskin) + "_jump"
			skin_animatedsprites[i].play(skin_animation)
		else:
			skin_animatedsprites[i].play("default_jump")
		
		if "accessory" in score:
			var accessory_animation = str(score.accessory) + "_jump"
			accessory_animatedsprites[i].play(accessory_animation)
		else:
			accessory_animatedsprites[i].play("none_jump")
	
	for i in range(top_scores.size(), 3):
		name_labels[i].text = "---"
		win_labels[i].text = "0"
		skin_animatedsprites[i].play("default_jump")
		accessory_animatedsprites[i].play("none_jump")
	
	update_player_wins(data)

func update_player_wins(data):
	if Global.firebase_id != "":
		if data.has(Global.firebase_id):
			var player_data = data[Global.firebase_id]
			var wins = player_data.get("wins", 0)
			playerwins_label.text = str(wins) + "w"
		else:
			playerwins_label.text = "0"
	else:
		playerwins_label.text = " "

func show_placeholder_data():
	for i in range(3):
		name_labels[i].text = "Player " + str(i+1)
		win_labels[i].text = "0"
		skin_animatedsprites[i].play("1_jump")
		accessory_animatedsprites[i].play("none_jump")
	
	playerwins_label.text = "?"

func _on_refresh_button_pressed():
	fetch_leaderboard()
