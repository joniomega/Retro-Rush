extends Node2D

@onready var tilemaplayer = $TileMapLayer
@export var current_level: int = 1
@onready var levels_path: String = "res://scenes/levels/"
@onready var spike_facingup_path: String = "res://assets/obstacles/spike.tscn"
@onready var coin_vase_path: String = "res://assets/obstacles/coin_vase.tscn"
@onready var decoration_path: String = "res://assets/obstacles/decoration.tscn"

# Replace this with your actual tile source ID for your "Auto" tile.
const AUTO_TILE_SOURCE_ID: int = 0

func _ready():
	load_level(current_level)

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
		y += 1

	# Now update all these positions in one call for the terrain tile.
	tilemaplayer.set_cells_terrain_connect(terrain_coords, AUTO_TILE_SOURCE_ID, 0, 0)
