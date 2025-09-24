extends Node2D

@onready var base_tilemap = $base
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

const AUTO_TILE_SOURCE_ID: int = 0

var level_parts: Dictionary = {}
var available_modules: Array = []
var recent_modules: Array = []
var current_groups: Dictionary = {}
var current_group: int = 0
var player_group: int = 0
var modules_per_group: int = 1
var cumulative_height: int = 0
@onready var player = $player

func _ready():
	var global = Global
	global.selected_level = -1
	load_level_parts("res://scenes/levels/lvlparts.txt")
	initialize_infinite_level()
	
	if global.selected_level_special == true:
		var special_material = preload("res://assets/shaders/backmaterial_special.tres")
		$CanvasLayer/background.material = special_material
	else:
		var biome_material = preload("res://assets/shaders/backmaterial_1.tres")
		if Global.selected_level > 6:
			biome_material = preload("res://assets/shaders/backmaterial_2.tres")
		if Global.selected_level > 12:
			biome_material = preload("res://assets/shaders/backmaterial_3.tres")
		if Global.selected_level > 18:
			biome_material = preload("res://assets/shaders/backmaterial_4.tres")
		if Global.selected_level > 24:
			biome_material = preload("res://assets/shaders/backmaterial_5.tres")
		$CanvasLayer/background.material = biome_material
	if Global.revival != null:
		player.global_position = Global.revival

func load_level_parts(file_path: String):
	if not FileAccess.file_exists(file_path):
		push_error("Level parts file not found: " + file_path)
		return
	var file = FileAccess.open(file_path, FileAccess.READ)
	if not file:
		push_error("Could not open level parts file: " + file_path)
		return
	var current_part_name: String = ""
	var current_part_data: Array = []
	while not file.eof_reached():
		var line: String = file.get_line().strip_edges()
		if line.is_empty() or (line.begins_with("#") and not line.begins_with("#START") and not line.begins_with("#MODULAR") and not line.begins_with("#END")):
			continue
		if line.begins_with("#START") or line.begins_with("#MODULAR") or line.begins_with("#END"):
			if current_part_name != "" and current_part_data.size() > 0:
				level_parts[current_part_name] = current_part_data.duplicate()
			current_part_name = line.substr(1)
			current_part_data.clear()
		elif line != "" and not line.begins_with("#"):
			current_part_data.append(line)
	if current_part_name != "" and current_part_data.size() > 0:
		level_parts[current_part_name] = current_part_data.duplicate()
	file.close()
	for part_name in level_parts.keys():
		if part_name.begins_with("MODULAR"):
			available_modules.append(part_name)
	print("Loaded level parts: ", level_parts.keys())
	print("Available modules: ", available_modules)

func initialize_infinite_level():
	clear_level()
	cumulative_height = 0
	
	var start_modules = []
	for part_name in level_parts.keys():
		if part_name.begins_with("START"):
			start_modules.append(part_name)
	if start_modules.size() == 0:
		push_error("No START modules found!")
		return
	
	# Generate initial groups
	for i in range(0, 3):
		generate_group(i)
	
	current_group = 2
	player_group = 0

func generate_group(group_number: int):
	# Create a new group node
	var group_node = Node2D.new()
	group_node.name = "Group_%d" % group_number
	add_child(group_node)
	
	# Create a unique TileMapLayer for this group
	var tilemap_layer = TileMapLayer.new()
	tilemap_layer.name = "TileMapLayer"
	tilemap_layer.tile_set = base_tilemap.tile_set
	group_node.add_child(tilemap_layer)
	
	# Select modules for this group
	var modules_for_group: Array = []
	
	for i in range(modules_per_group):
		var available = get_available_modules()
		if available.size() == 0:
			push_error("No available modules!")
			return
		
		var selected_module = available[randi() % available.size()]
		modules_for_group.append(selected_module)
		recent_modules.append(selected_module)
		
		if recent_modules.size() > 3:
			recent_modules.pop_front()
	
	# Store the group information
	current_groups[group_number] = {
		"node": group_node,
		"tilemap": tilemap_layer,
		"modules": modules_for_group,
		"start_y": cumulative_height
	}
	
	# Place the modules in this group
	place_module_group(group_number, modules_for_group, tilemap_layer, group_node)
	
	# Update cumulative height for next group
	var group_height = get_total_group_height(modules_for_group)
	cumulative_height += group_height
	
	print("Generated group ", group_number, " starting at Y: ", current_groups[group_number]["start_y"] * 32)

func get_available_modules() -> Array:
	var available: Array = []
	for module in available_modules:
		if not recent_modules.has(module):
			available.append(module)
	if available.size() == 0:
		available = available_modules.duplicate()
	return available

func place_module_group(group_number: int, module_names: Array, tilemap_layer: TileMapLayer, group_node: Node2D):
	var group_data = current_groups[group_number]
	var start_y = group_data["start_y"]
	var current_y = start_y
	
	for module_name in module_names:
		var module_data = level_parts.get(module_name, [])
		if module_data.size() == 0:
			push_error("Module data not found for: " + module_name)
			continue
		
		place_module(module_data, current_y, tilemap_layer, group_node)
		current_y += module_data.size()

func place_module(module_data: Array, start_y: int, tilemap_layer: TileMapLayer, group_node: Node2D):
	# Preload scenes
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
	
	var terrain_coords: Array[Vector2i] = []
	
	for y in range(module_data.size()):
		var line: String = module_data[y]
		for x in range(line.length()):
			var char = line[x]
			var world_y = start_y + y
			
			if char == '1':
				terrain_coords.append(Vector2i(x, world_y))
			elif char == '2' and vase_scene:
				var vase_instance = vase_scene.instantiate()
				vase_instance.position = Vector2(x * 32, world_y * 32)
				vase_instance.add_to_group("vases")
				group_node.add_child(vase_instance)
			elif char == '3' and spike_scene:
				var spike_instance = spike_scene.instantiate()
				spike_instance.position = Vector2(x * 32, world_y * 32)
				spike_instance.add_to_group("spikes")
				group_node.add_child(spike_instance)
			elif char == '4' and decoration_scene:
				var decoration_instance = decoration_scene.instantiate()
				decoration_instance.position = Vector2(x * 32, world_y * 32)
				decoration_instance.add_to_group("decorations")
				group_node.add_child(decoration_instance)
			elif char == '5' and relic_scene:
				var relic_instance = relic_scene.instantiate()
				relic_instance.position = Vector2(x * 32, world_y * 32)
				group_node.add_child(relic_instance)
			elif char == '6' and saw_scene:
				var saw_instance = saw_scene.instantiate()
				saw_instance.position = Vector2(x * 32, world_y * 32)
				group_node.add_child(saw_instance)
			elif char == '7' and bugfly_scene:
				var bugfly_instance = bugfly_scene.instantiate()
				bugfly_instance.position = Vector2(x * 32, world_y * 32)
				group_node.add_child(bugfly_instance)
			elif char == '8' and bugwalk_scene:
				var bugwalk_instance = bugwalk_scene.instantiate()
				bugwalk_instance.position = Vector2(x * 32, world_y * 32)
				group_node.add_child(bugwalk_instance)
			elif char == '9' and bugboss_scene:
				var bugboss_instance = bugboss_scene.instantiate()
				bugboss_instance.position = Vector2(x * 32, world_y * 32)
				group_node.add_child(bugboss_instance)
			elif char == 'w' and webbarrier_scene:
				var webbarrier_instance = webbarrier_scene.instantiate()
				webbarrier_instance.position = Vector2(x * 32, world_y * 32)
				group_node.add_child(webbarrier_instance)
			elif char == 'j' and jumppad_scene:
				var jumppad_instance = jumppad_scene.instantiate()
				jumppad_instance.position = Vector2(x * 32, world_y * 32)
				group_node.add_child(jumppad_instance)
			elif char == 'r' and revival_scene:
				var revival_instance = revival_scene.instantiate()
				revival_instance.position = Vector2(x * 32, world_y * 32)
				group_node.add_child(revival_instance)
			elif char == 's' and spear_scene:
				var spear_instance = spear_scene.instantiate()
				# Check for wall to determine spear direction
				var has_left_wall = false
				if x > 0:
					# Check if there's a '1' to the left in the same row
					has_left_wall = module_data[y].substr(0, x).contains('1')
				spear_instance.right = not has_left_wall
				spear_instance.position = Vector2(x * 32, world_y * 32)
				group_node.add_child(spear_instance)
	
	# Update terrain tiles
	if terrain_coords.size() > 0:
		tilemap_layer.set_cells_terrain_connect(terrain_coords, 0, 0)

func clear_level():
	# Clear all groups
	for group_number in current_groups.keys():
		var group_node = current_groups[group_number]["node"]
		if is_instance_valid(group_node):
			group_node.queue_free()
	
	current_groups.clear()
	cumulative_height = 0
	
	# Clear any remaining objects
	for spike in get_tree().get_nodes_in_group("spikes"):
		spike.queue_free()
	for vase in get_tree().get_nodes_in_group("vases"):
		vase.queue_free()
	for deco in get_tree().get_nodes_in_group("decorations"):
		deco.queue_free()

func _process(_delta):
	if player:
		# Calculate which group the player is in
		var player_y_tile = int(player.global_position.y / 32)
		var player_y_group = -1
		
		# Get sorted group numbers
		var group_numbers = current_groups.keys()
		group_numbers.sort()
		
		# Find which group the player is in
		for group_num in group_numbers:
			var group_data = current_groups[group_num]
			var group_start = group_data["start_y"]
			var group_height = get_total_group_height(group_data["modules"])
			var group_end = group_start + group_height
			
			if player_y_tile >= group_start and player_y_tile < group_end:
				player_y_group = group_num
				break
		
		# If player is not in any group (shouldn't happen), default to 0
		if player_y_group == -1:
			player_y_group = 0
		
		# Check if player moved to a new group
		if player_y_group > player_group:
			player_group = player_y_group
			print("Player entered group ", player_group)
			
			# Generate new group if needed
			if player_group >= current_group - 1:
				var new_group = current_group + 1
				generate_group(new_group)
				current_group = new_group
				print("Generated new group ", new_group)
				
				# Delete group that's 2 groups behind
				var group_to_delete = player_group - 2
				if group_to_delete >= 0 and current_groups.has(group_to_delete):
					delete_group(group_to_delete)
					print("Deleted group ", group_to_delete)

func get_total_group_height(module_names: Array) -> int:
	var total_height = 0
	for module_name in module_names:
		var module_data = level_parts.get(module_name, [])
		total_height += module_data.size()
	return total_height

func delete_group(group_number: int):
	if current_groups.has(group_number):
		var group_data = current_groups[group_number]
		var group_node = group_data["node"]
		
		# Remove the entire group node
		if is_instance_valid(group_node):
			group_node.queue_free()
		
		# Remove from tracking
		current_groups.erase(group_number)
		
		print("Deleted group ", group_number)

func stop_music():
	$AnimationPlayer.play("stop")
