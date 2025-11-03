extends Node2D

@onready var tilemaplayer = $TileMapLayer
@onready var tilemaplayer2 = $TileMapLayer2
@export var current_level: int = 1
@onready var levels_path: String = "res://scenes/levels/"
@onready var spike_facingup_path: String = "res://assets/obstacles/spike.tscn"
@onready var coin_vase_path: String = "res://assets/obstacles/coin_vase.tscn"
@onready var decoration_path: String = "res://assets/obstacles/decoration.tscn"
@onready var relic_path: String = "res://assets/obstacles/relic.tscn"
@onready var sawdown_path: String = "res://assets/obstacles/sawdown.tscn"
@onready var bugfly_path: String = "res://assets/obstacles/bug_fly.tscn"
@onready var bugwalk_path: String = "res://assets/obstacles/bug_centipide.tscn"
@onready var bugboss_path: String = "res://assets/obstacles/bug_giantcrawler.tscn"
@onready var webbarrier_path: String = "res://assets/obstacles/web_barrier.tscn"
@onready var jumppad_path: String = "res://assets/obstacles/jumppad.tscn"
@onready var revival_path: String = "res://assets/obstacles/revive_altar.tscn"
@onready var spear_path: String = "res://assets/obstacles/trap_spear.tscn"
#AUTOTILESET 2
@export var auto2_frequency: int = randi_range(15, 25)  # how many normal lines before using Auto2
@export var auto2_length: int = randi_range(5, 10)      # how many lines use Auto2
# Terrain set IDs
const AUTO_TILE_SOURCE_ID: int = 0
const AUTO2_TILE_SOURCE_ID: int = 1

func _ready():
	var random_index = str(randi_range(1, 4))
	$decoration.play(random_index)
	var global = Global
	current_level = global.selected_level
	load_level(current_level)

	if global.selected_level_special == true:
		var special_material = preload("res://assets/shaders/backmaterial_special.tres")
		$CanvasLayer/background.material = special_material
	else:
		var biome_material = preload("res://assets/shaders/backmaterial_1.tres")
		if current_level > 6:
			biome_material = preload("res://assets/shaders/backmaterial_2.tres")
		if current_level > 12:
			biome_material = preload("res://assets/shaders/backmaterial_3.tres")
		if current_level > 18:
			biome_material = preload("res://assets/shaders/backmaterial_4.tres")
		if current_level > 24:
			biome_material = preload("res://assets/shaders/backmaterial_5.tres")
		$CanvasLayer/background.material = biome_material

	if Global.revival != null:
		$player.global_position = Global.revival


func load_level(level_number: int):
	var file_path = "%slvl_%d.txt" % [levels_path, level_number]
	if not FileAccess.file_exists(file_path):
		push_error("Level file not found: " + file_path)
		return

	var file = FileAccess.open(file_path, FileAccess.READ)
	if not file:
		push_error("Could not open level file: " + file_path)
		return

	tilemaplayer.clear()

	for spike in get_tree().get_nodes_in_group("spikes"):
		spike.queue_free()
	for vase in get_tree().get_nodes_in_group("vases"):
		vase.queue_free()
	for deco in get_tree().get_nodes_in_group("decorations"):
		deco.queue_free()

	var spike_scene = load(spike_facingup_path)
	var vase_scene = load(coin_vase_path)
	var decoration_scene = load(decoration_path)
	var relic_scene = load(relic_path)
	var saw_scene = load(sawdown_path)
	var bugfly_scene = load(bugfly_path)
	var bugwalk_scene = load(bugwalk_path)
	var bugboss_scene = load(bugboss_path)
	var webbarrier_scene = load(webbarrier_path)
	var jumppad_scene = load(jumppad_path)
	var revival_scene = load(revival_path)
	var spear_scene = load(spear_path)

	if [spike_scene, vase_scene, decoration_scene, relic_scene, saw_scene, bugfly_scene, bugwalk_scene, bugboss_scene].has(null):
		push_error("One or more scene paths are invalid.")
		return

	var terrain_coords_auto: Array[Vector2i] = []
	var terrain_coords_auto2: Array[Vector2i] = []

	var y: int = 0
	while not file.eof_reached():
		var line: String = file.get_line()
		var use_auto2 := ((y % (auto2_frequency + auto2_length)) >= auto2_frequency)

		for x in range(line.length()):
			var char = line[x]
			match char:
				'1':
					if use_auto2:
						terrain_coords_auto2.append(Vector2i(x, y))
					else:
						terrain_coords_auto.append(Vector2i(x, y))
				'2':
					var vase_instance = vase_scene.instantiate()
					vase_instance.position = Vector2(x * 32, y * 32)
					vase_instance.add_to_group("vases")
					add_child(vase_instance)
				'3':
					var spike_instance = spike_scene.instantiate()
					spike_instance.position = Vector2(x * 32, y * 32)
					spike_instance.add_to_group("spikes")
					add_child(spike_instance)
				'4':
					var decoration_instance = decoration_scene.instantiate()
					decoration_instance.position = Vector2(x * 32, y * 32)
					decoration_instance.add_to_group("decorations")
					add_child(decoration_instance)
				'5':
					var relic_instance = relic_scene.instantiate()
					relic_instance.position = Vector2(x * 32, y * 32)
					add_child(relic_instance)
				'6':
					var saw_instance = saw_scene.instantiate()
					saw_instance.position = Vector2(x * 32, y * 32)
					add_child(saw_instance)
				'7':
					var bugfly_instance = bugfly_scene.instantiate()
					bugfly_instance.position = Vector2(x * 32, y * 32)
					add_child(bugfly_instance)
				'8':
					var bugwalk_instance = bugwalk_scene.instantiate()
					bugwalk_instance.position = Vector2(x * 32, y * 32)
					add_child(bugwalk_instance)
				'9':
					var bugboss_instance = bugboss_scene.instantiate()
					bugboss_instance.position = Vector2(x * 32, y * 32)
					add_child(bugboss_instance)
				'w':
					var webbarrier_instance = webbarrier_scene.instantiate()
					webbarrier_instance.position = Vector2(x * 32, y * 32)
					add_child(webbarrier_instance)
				'j':
					var jumppad_instance = jumppad_scene.instantiate()
					jumppad_instance.position = Vector2(x * 32, y * 32)
					add_child(jumppad_instance)
				'r':
					var revival_instance = revival_scene.instantiate()
					revival_instance.position = Vector2(x * 32, y * 32)
					add_child(revival_instance)
				's':
					var spear_instance = spear_scene.instantiate()
					var spear_pos = Vector2i(x, y)
					if terrain_coords_auto.has(Vector2i(x - 1, y)) or terrain_coords_auto2.has(Vector2i(x - 1, y)):
						spear_instance.right = false
					else:
						spear_instance.right = true
					spear_instance.position = Vector2(x * 32, y * 32)
					add_child(spear_instance)
		y += 1

	tilemaplayer.set_cells_terrain_connect(terrain_coords_auto, AUTO_TILE_SOURCE_ID, 0, 0)
	tilemaplayer2.set_cells_terrain_connect(terrain_coords_auto2, AUTO2_TILE_SOURCE_ID, 0, 0)


func stop_music():
	$AnimationPlayer.play("stop")
	pass
