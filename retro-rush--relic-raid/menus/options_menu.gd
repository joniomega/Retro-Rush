extends CanvasLayer

@onready var masterslider = $Node2D/label_master/masterslider
@onready var musicslider = $Node2D/label_music/musicslider
@onready var effectsslider = $Node2D/label_effects/effectsslider
@onready var textedit_name = $Node2D/TextEdit
var has_player_name = false
var http_request: HTTPRequest  # For player operations
@export var is_online: bool = false

# Volume settings
const MIN_DB := -30.0
const MAX_DB := 30.0
const MID_DB := 0.0
const SLIDER_MIN := 0.0
const SLIDER_MAX := 1.0
const SLIDER_MID := 0.5

func _ready():
	if is_online == false:
		$Node2D/TextEdit.visible = false
		$Node2D/Buttonchangename.visible = false
		$Node2D/Buttonchangename.disabled = true
	if is_online == true:
		$Node2D/TextEdit.visible = true
		$Node2D/Buttonchangename.visible = true
		$Node2D/Buttonchangename.disabled = false
	$AnimationPlayer.play("start")
	
	# ✅ Create HTTPRequest dynamically like in your leaderboard script
	http_request = HTTPRequest.new()
	add_child(http_request)
	http_request.request_completed.connect(_on_request_completed)

	# Convert stored dB → slider positions
	masterslider.value = db_to_slider(Global.master_volume)
	musicslider.value = db_to_slider(Global.music_volume)
	effectsslider.value = db_to_slider(Global.effects_volume)

	if Global.player_name != "":
		textedit_name.text = Global.player_name
		has_player_name = true
	else:
		$Node2D/Buttonchangename.visible = false
		$Node2D/TextEdit.visible = false
		has_player_name = false


func _on_button_pressed() -> void:
	$button_press.play()
	Global.save_progress()
	$AnimationPlayer.play("end")
	await get_tree().create_timer(0.6).timeout
	queue_free()


func _on_masterslider_value_changed(value: float) -> void:
	var db = slider_to_db(value)
	Global.master_volume = db
	AudioServer.set_bus_volume_db(AudioServer.get_bus_index("Master"), db)

func _on_musicslider_value_changed(value: float) -> void:
	var db = slider_to_db(value)
	Global.music_volume = db
	AudioServer.set_bus_volume_db(AudioServer.get_bus_index("Music"), db)

func _on_effectsslider_value_changed(value: float) -> void:
	var db = slider_to_db(value)
	Global.effects_volume = db
	AudioServer.set_bus_volume_db(AudioServer.get_bus_index("SFX"), db)


# --- Conversion helpers ---
func slider_to_db(value: float) -> float:
	if value <= SLIDER_MIN:
		return MIN_DB
	elif value >= SLIDER_MAX:
		return MAX_DB
	elif value < SLIDER_MID:
		return lerp(MIN_DB, MID_DB, value / SLIDER_MID)
	else:
		return lerp(MID_DB, MAX_DB, (value - SLIDER_MID) / (SLIDER_MAX - SLIDER_MID))

func db_to_slider(db: float) -> float:
	if db <= MIN_DB:
		return SLIDER_MIN
	elif db >= MAX_DB:
		return SLIDER_MAX
	elif db < MID_DB:
		return inverse_lerp(MIN_DB, MID_DB, db) * SLIDER_MID
	else:
		return SLIDER_MID + inverse_lerp(MID_DB, MAX_DB, db) * (SLIDER_MAX - SLIDER_MID)


func _on_buttonchangename_pressed() -> void:
	var new_name = textedit_name.text.strip_edges()
	if new_name == "":
		has_player_name = false
		return
	
	has_player_name = true
	var current_id = Global.firebase_id
	Global.player_name = new_name
	
	if Global.firebase_id == "":
		pass # Could call submit_new_player here if needed
	else:
		update_existing_player(current_id, new_name)


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


# ✅ Handle responses if you want to check update success
func _on_request_completed(result, response_code, headers, body):
	if result != HTTPRequest.RESULT_SUCCESS:
		print("Request failed: ", result)
		return
	if response_code != 200:
		print("HTTP error: ", response_code, " → ", body.get_string_from_utf8())
	else:
		print("Player updated successfully")
