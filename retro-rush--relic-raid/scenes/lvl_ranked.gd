extends Node2D

@onready var tilemaplayer = $TileMapLayer
@onready var score_to_beat_label = $Control/CanvasLayer2/score
@onready var background = $CanvasLayer/background
@onready var player = $player

@export var current_level: int = 1
@onready var levels_path: String = "res://scenes/levels/ranked_lvl_"
@onready var spike_facingup_path: String = "res://assets/obstacles/spike.tscn"
@onready var coin_vase_path: String = "res://assets/obstacles/coin_vase.tscn"
@onready var decoration_path: String = "res://assets/obstacles/decoration.tscn"
@onready var relic_path: String = "res://assets/obstacles/relic.tscn"
@onready var sawdown_path: String = "res://assets/obstacles/sawdown.tscn"
@onready var bugfly_path: String = "res://assets/obstacles/bug_fly.tscn"
@onready var bugwalk_path: String = "res://assets/obstacles/bug_centipide.tscn"
@onready var bugboss_path: String = "res://assets/obstacles/bug_giantcrawler.tscn"

const AUTO_TILE_SOURCE_ID: int = 0
var target_score: int = 0
var player_score: int = 0
var match_complete: bool = false

func _ready():
	print("Ranked level scene loaded")
	print("Global opponent data: ", Global.ranked_opponent_name, " | Score: ", Global.ranked_opponent_score)
	
	setup_ranked_match()
	load_ranked_level(Global.ranked_level)
	setup_ui()

func setup_ranked_match():
	# Set background material from global
	background.material = Global.ranked_biome_material
	
	# Get opponent data from global
	target_score = Global.ranked_opponent_score
	var opponent_name = Global.ranked_opponent_name
	
	print("Setting up match against: ", opponent_name, " | Target score: ", target_score)
	
	# Initialize score tracking
	player_score = 0
	match_complete = false

func setup_ui():
	if score_to_beat_label == null:
		push_error("score_to_beat_label is not assigned!")
		return
	
	var display_text = str(target_score)
	score_to_beat_label.text = display_text
	score_to_beat_label.visible = true
	
	print("UI Setup Complete - Label Text: ", display_text)

func load_ranked_level(level_number: int):
	var file_path = "%s%d.txt" % [levels_path, level_number]
	print("Loading ranked level from: ", file_path)
	
	if not FileAccess.file_exists(file_path):
		push_error("Ranked level file not found: " + file_path)
		return

	var file = FileAccess.open(file_path, FileAccess.READ)
	if not file:
		push_error("Could not open ranked level file: " + file_path)
		return
	
	# Clear existing level
	tilemaplayer.clear()
	clear_obstacles()
	
	# Preload obstacle scenes
	var spike_scene = load(spike_facingup_path)
	var vase_scene = load(coin_vase_path)
	var decoration_scene = load(decoration_path)
	var relic_scene = load(relic_path)
	var saw_scene = load(sawdown_path)
	var bugfly_scene = load(bugfly_path)
	var bugwalk_scene = load(bugwalk_path)
	var bugboss_scene = load(bugboss_path)
	
	# Load level layout
	var terrain_coords: Array[Vector2i] = []
	var y: int = 0
	
	while not file.eof_reached():
		var line: String = file.get_line()
		for x in range(line.length()):
			var char = line[x]
			var pos = Vector2(x * 32, y * 32)
			
			match char:
				'1':
					terrain_coords.append(Vector2i(x, y))
				'2':
					spawn_obstacle(vase_scene, pos, "vases")
				'3':
					spawn_obstacle(spike_scene, pos, "spikes")
				'4':
					spawn_obstacle(decoration_scene, pos, "decorations")
				'5':
					spawn_obstacle(relic_scene, pos)
				'6':
					spawn_obstacle(saw_scene, pos)
				'7':
					spawn_obstacle(bugfly_scene, pos)
				'8':
					spawn_obstacle(bugwalk_scene, pos)
				'9':
					spawn_obstacle(bugboss_scene, pos)
		y += 1
	
	# Set terrain tiles
	tilemaplayer.set_cells_terrain_connect(terrain_coords, AUTO_TILE_SOURCE_ID, 0, 0)
	print("Level loaded successfully")

func spawn_obstacle(scene: PackedScene, position: Vector2, group: String = ""):
	if scene == null:
		push_error("Scene not loaded")
		return
	
	var instance = scene.instantiate()
	instance.position = position
	if group != "":
		instance.add_to_group(group)
	add_child(instance)

func clear_obstacles():
	for group in ["spikes", "vases", "decorations"]:
		for node in get_tree().get_nodes_in_group(group):
			node.queue_free()

func update_score(points: int):
	player_score += points
	print("Score updated: ", player_score)
	check_victory()

func check_victory():
	if not match_complete and player_score >= target_score:
		match_complete = true
		print("Victory achieved! Final score: ", player_score)
		victory_sequence()

func victory_sequence():
	score_to_beat_label.text = "VICTORY! Score: %d" % player_score
	print("Victory sequence started")
	await get_tree().create_timer(3.0).timeout
	return_to_menu()

func return_to_menu():
	print("Returning to menu")
	TransitionScreen.transition()
	await TransitionScreen.on_transition_finished
	get_tree().change_scene_to_file("res://scenes/main_menu.tscn")

func stop_music():
	$AnimationPlayer.play("stop")

func _on_player_death():
	score_to_beat_label.text = "FAILED! Score: %d" % player_score
	print("Player died - Final score: ", player_score)
	await get_tree().create_timer(3.0).timeout
	return_to_menu()
func end():
	$Control/CanvasLayer2/score.visible = false
