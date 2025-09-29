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
@onready var player_ghost_path: String = "res://assets/characters/player/player_ghost.tscn"

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

# Score tracking
var score_counter: int = 0

# Ghost placement system
var player_ghost_scene: PackedScene
var leaderboard_data: Dictionary = {}
var ghost_placement_enabled: bool = false
var placed_ghost_ids: Array = []  # Track which player IDs already have ghosts

func _ready():
	var global = Global
	global.selected_level = -1
	load_level_parts("res://scenes/levels/lvlparts.txt")
	initialize_infinite_level()
	
	# Load player ghost scene
	player_ghost_scene = load(player_ghost_path)
	
	# Fetch leaderboard data for ghost placement
	fetch_leaderboard_for_ghosts()

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
		if part_name.begins_with("MODULAR") or part_name.begins_with("START"):
			available_modules.append(part_name)
	print("Loaded level parts: ", level_parts.keys())
	print("Available modules: ", available_modules)

func initialize_infinite_level():
	clear_level()
	cumulative_height = 0
	
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
		var available = get_available_modules(group_number)
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

func get_available_modules(group_number: int) -> Array:
	var available: Array = []
	
	# For the first group (group 0), only use START modules
	if group_number == 0:
		for module in available_modules:
			if module.begins_with("START") and not recent_modules.has(module):
				available.append(module)
		# If no START modules are available, fall back to all START modules
		if available.size() == 0:
			for module in available_modules:
				if module.begins_with("START"):
					available.append(module)
	else:
		# For other groups, use MODULAR modules (existing logic)
		for module in available_modules:
			if module.begins_with("MODULAR") and not recent_modules.has(module):
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
			var world_position = Vector2(x * 32, world_y * 32)
			
			if char == '1':
				terrain_coords.append(Vector2i(x, world_y))
			elif char == '2' and vase_scene:
				var vase_instance = vase_scene.instantiate()
				vase_instance.position = world_position
				vase_instance.add_to_group("vases")
				group_node.add_child(vase_instance)
				
				# Connect to score counter
				if vase_instance.has_signal("collected"):
					vase_instance.collected.connect(_on_vase_collected)
				
				# Place ghost for vase if enabled
				if ghost_placement_enabled:
					try_place_ghost(world_position, 25, group_node)
					
			elif char == '3' and spike_scene:
				var spike_instance = spike_scene.instantiate()
				spike_instance.position = world_position
				spike_instance.add_to_group("spikes")
				group_node.add_child(spike_instance)
			elif char == '4' and decoration_scene:
				var decoration_instance = decoration_scene.instantiate()
				decoration_instance.position = world_position
				decoration_instance.add_to_group("decorations")
				group_node.add_child(decoration_instance)
			elif char == '5' and relic_scene:
				var relic_instance = relic_scene.instantiate()
				relic_instance.position = world_position
				group_node.add_child(relic_instance)
			elif char == '6' and saw_scene:
				var saw_instance = saw_scene.instantiate()
				saw_instance.position = world_position
				group_node.add_child(saw_instance)
			elif char == '7' and bugfly_scene:
				var bugfly_instance = bugfly_scene.instantiate()
				bugfly_instance.position = world_position
				group_node.add_child(bugfly_instance)
				
				# Connect to score counter
				if bugfly_instance.has_signal("defeated"):
					bugfly_instance.defeated.connect(_on_bugfly_defeated)
				
				# Place ghost for bugfly if enabled
				if ghost_placement_enabled:
					try_place_ghost(world_position, 10, group_node)
					
			elif char == '8' and bugwalk_scene:
				var bugwalk_instance = bugwalk_scene.instantiate()
				bugwalk_instance.position = world_position
				group_node.add_child(bugwalk_instance)
			elif char == '9' and bugboss_scene:
				var bugboss_instance = bugboss_scene.instantiate()
				bugboss_instance.position = world_position
				group_node.add_child(bugboss_instance)
			elif char == 'w' and webbarrier_scene:
				var webbarrier_instance = webbarrier_scene.instantiate()
				webbarrier_instance.position = world_position
				group_node.add_child(webbarrier_instance)
			elif char == 'j' and jumppad_scene:
				var jumppad_instance = jumppad_scene.instantiate()
				jumppad_instance.position = world_position
				group_node.add_child(jumppad_instance)
			elif char == 'r' and revival_scene:
				var revival_instance = revival_scene.instantiate()
				revival_instance.position = world_position
				group_node.add_child(revival_instance)
			elif char == 's' and spear_scene:
				var spear_instance = spear_scene.instantiate()
				var has_left_wall = false
				if x > 0:
					# Check if the tile immediately left is '1'
					has_left_wall = module_data[y][x - 1] == '1'
				spear_instance.right = not has_left_wall
				spear_instance.position = world_position
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
	
	# Clear placed ghost IDs for next run
	placed_ghost_ids.clear()

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

# Score tracking functions
func _on_vase_collected():
	score_counter += 25
	print("Vase collected! Score: ", score_counter)

func _on_bugfly_defeated():
	score_counter += 10
	print("Bugfly defeated! Score: ", score_counter)

# Ghost placement system
func fetch_leaderboard_for_ghosts():
	var http_request = HTTPRequest.new()
	add_child(http_request)
	http_request.request_completed.connect(_on_ghost_leaderboard_loaded)
	
	var url = "https://retrorush-descend-default-rtdb.europe-west1.firebasedatabase.app/leaderboard.json"
	var error = http_request.request(url)
	
	if error != OK:
		push_error("Failed to fetch leaderboard for ghosts")

func _on_ghost_leaderboard_loaded(result, response_code, headers, body):
	if result != HTTPRequest.RESULT_SUCCESS:
		print("Ghost leaderboard request failed")
		return
	
	if response_code != 200:
		push_error("HTTP error " + str(response_code))
		return
	
	var json = JSON.new()
	var parse_error = json.parse(body.get_string_from_utf8())
	
	if parse_error != OK:
		push_error("JSON parse error: " + str(parse_error))
		return
	
	var data = json.get_data()
	
	if data == null or typeof(data) != TYPE_DICTIONARY:
		return
	
	leaderboard_data = data
	ghost_placement_enabled = true
	print("Ghost placement enabled with ", leaderboard_data.size(), " players")

func try_place_ghost(position: Vector2, points_value: int, group_node: Node2D):
	if leaderboard_data.is_empty():
		return
	
	# Calculate cumulative score at this position
	var cumulative_score = calculate_cumulative_score(position.y)
	
	# Find eligible players (excluding current player and already placed ghosts)
	var eligible_players = []
	
	for player_id in leaderboard_data:
		# Skip current player
		if player_id == Global.firebase_id:
			continue
		
		# Skip if we already placed a ghost for this player
		if placed_ghost_ids.has(player_id):
			continue
		
		var player_data = leaderboard_data[player_id]
		
		# Skip players with 0 wins
		var player_wins = player_data.get("wins", 0)
		if player_wins <= 0:
			continue
		
		# Check if player has similar score (±5)
		if abs(player_wins - cumulative_score) <= 5:
			eligible_players.append({
				"id": player_id,
				"data": player_data
			})
	
	# If we found eligible players, place a ghost
	if eligible_players.size() > 0:
		var selected_player = eligible_players[randi() % eligible_players.size()]
		var player_data = selected_player["data"]
		
		# Mark this player ID as having a ghost placed
		placed_ghost_ids.append(selected_player["id"])
		
		# Create ghost instance
		var ghost_instance = player_ghost_scene.instantiate()
		
		# Set ghost properties
		ghost_instance.username = player_data.get("name", "Player")
		ghost_instance.skin = str(player_data.get("skin", 1))
		ghost_instance.accessory = player_data.get("accessory", "none")
		ghost_instance.position = position
		
		# Debug print
		print("Placed ghost for player: ", ghost_instance.username, 
			" | Skin: ", ghost_instance.skin, 
			" | Accessory: ", ghost_instance.accessory,
			" | Wins: ", player_data.get("wins", 0),
			" | Cumulative Score: ", cumulative_score)
		
		# Add to group node
		group_node.add_child(ghost_instance)

func calculate_cumulative_score(y_position: float) -> int:
	# Calculate an approximate cumulative score based on vertical position
	# This is a simple estimation - you can adjust the formula as needed
	var tiles_from_start = y_position / 32.0
	var estimated_score = int(tiles_from_start * 2)  # Adjust this multiplier as needed
	
	return estimated_score
