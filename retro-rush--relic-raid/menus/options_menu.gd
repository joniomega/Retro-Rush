# options_menu.gd
extends CanvasLayer


@onready var masterslider = $Node2D/label_master/masterslider
@onready var musicslider = $Node2D/label_music/musicslider
@onready var effectsslider = $Node2D/label_effects/effectsslider

# Volume settings
const MIN_DB := -30.0
const MAX_DB := 30.0
const MID_DB := 0.0
const SLIDER_MIN := 0.0
const SLIDER_MAX := 1.0
const SLIDER_MID := 0.5

func _ready():
	$AnimationPlayer.play("start")
	# Convert stored dB → slider positions
	masterslider.value = db_to_slider(Global.master_volume)
	musicslider.value = db_to_slider(Global.music_volume)
	effectsslider.value = db_to_slider(Global.effects_volume)

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
		# Map 0..0.5 → MIN_DB..MID_DB
		return lerp(MIN_DB, MID_DB, value / SLIDER_MID)
	else:
		# Map 0.5..1 → MID_DB..MAX_DB
		return lerp(MID_DB, MAX_DB, (value - SLIDER_MID) / (SLIDER_MAX - SLIDER_MID))

func db_to_slider(db: float) -> float:
	if db <= MIN_DB:
		return SLIDER_MIN
	elif db >= MAX_DB:
		return SLIDER_MAX
	elif db < MID_DB:
		# Map MIN_DB..MID_DB → 0..0.5
		return inverse_lerp(MIN_DB, MID_DB, db) * SLIDER_MID
	else:
		# Map MID_DB..MAX_DB → 0.5..1
		return SLIDER_MID + inverse_lerp(MID_DB, MAX_DB, db) * (SLIDER_MAX - SLIDER_MID)
