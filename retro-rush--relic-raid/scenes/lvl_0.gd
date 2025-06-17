extends Node2D

@onready var tilemaplayer = $TileMapLayer
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

# Replace this with your actual tile source ID for your "Auto" tile.
const AUTO_TILE_SOURCE_ID: int = 0

func _ready():
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

func load_level(level_number: int):
	var file_path = "%slvl_%d.txt" % [levels_path, level_number]
	if not FileAccess.file_exists(file_path):
		push_error("Level file not found: " + file_path)
		return

	var file = FileAccess.open(file_path, FileAccess.READ)
	if not file:
		push_error("Could not open level file: " + file_path)
		return
	# Clear existing terrain cells.
	tilemaplayer.clear()
	# Remove any previously instantiated spikes by fetching nodes in the "spikes" group.
	for spike in get_tree().get_nodes_in_group("spikes"):
		spike.queue_free()
	for vase in get_tree().get_nodes_in_group("vases"):
		vase.queue_free()
	for deco in get_tree().get_nodes_in_group("decorations"):
		deco.queue_free()
	# Preload the spike scene once for efficiency.
	var spike_scene = load(spike_facingup_path)
	if spike_scene == null:
		push_error("Spike scene not found at path: " + spike_facingup_path)
		return
	var vase_scene = load(coin_vase_path)
	if vase_scene == null:
		push_error("Vase scene not found at path")
		return
	var decoration_scene = load(decoration_path)
	if decoration_scene == null:
		push_error("Decoration scene not found at path")
		return
	var relic_scene = load(relic_path)
	if relic_scene == null:
		push_error("relic scene not found at path")
		return
	var saw_scene = load(sawdown_path)
	if saw_scene == null:
		push_error("saw scene not found at path")
		return
	var bugfly_scene = load(bugfly_path)
	if bugfly_scene == null:
		push_error("enemy bugfly scene not found")
		return
	var bugwalk_scene = load(bugwalk_path)
	if bugwalk_scene == null:
		push_error("enemy bugwalk scene not found")
		return
	var bugboss_scene = load(bugboss_path)
	if bugboss_scene == null:
		push_error("enemy bugboss scene not found")
		return
	# Collect all positions where you want to place your terrain tile.
	var terrain_coords: Array[Vector2i] = []
	var y: int = 0
	while not file.eof_reached():
		var line: String = file.get_line()
		for x in range(line.length()):
			var char = line[x]
			if char == '1':
				terrain_coords.append(Vector2i(x, y))
			elif char == '2':
				var vase_instance = vase_scene.instantiate()
				vase_instance.position = Vector2(x * 32, y * 32)
				vase_instance.add_to_group("vases")
				add_child(vase_instance)
			elif char == '3':
				# Instantiate a spike when a '3' is encountered.
				var spike_instance = spike_scene.instantiate()
				# Set the position based on the grid assuming each tile/spike is 32x32 pixels.
				spike_instance.position = Vector2(x * 32, y * 32)
				# Add the spike to the "spikes" group for easier management.
				spike_instance.add_to_group("spikes")
				add_child(spike_instance)
			elif char == '4':
				var decoration_instance = decoration_scene.instantiate()
				decoration_instance.position = Vector2(x * 32, y * 32)
				decoration_instance.add_to_group("decorations")
				add_child(decoration_instance)
			elif char == '5':
				var relic_instance = relic_scene.instantiate()
				relic_instance.position = Vector2(x * 32, y * 32)
				add_child(relic_instance)
			elif char == '6':
				var saw_instance = saw_scene.instantiate()
				saw_instance.position = Vector2(x * 32, y * 32)
				add_child(saw_instance)
			elif char == '7':
				var bugfly_instance = bugfly_scene.instantiate()
				bugfly_instance.position = Vector2(x * 32, y * 32)
				add_child(bugfly_instance)
			elif char == '8':
				var bugwalk_instance = bugwalk_scene.instantiate()
				bugwalk_instance.position = Vector2(x * 32, y * 32)
				add_child(bugwalk_instance)
			elif char == '9':
				var bugboss_instance = bugboss_scene.instantiate()
				bugboss_instance.position = Vector2(x * 32, y * 32)
				add_child(bugboss_instance)
		y += 1
	# Now update all these positions in one call for the terrain tile.
	tilemaplayer.set_cells_terrain_connect(terrain_coords, AUTO_TILE_SOURCE_ID, 0, 0)
	# Add this after setting up the TileMap
func stop_music():
	$AnimationPlayer.play("stop")
	pass
