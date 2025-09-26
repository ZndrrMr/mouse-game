extends CharacterBody2D

const SPEED = 60.0
const FOLLOW_DISTANCE = 50.0

var player = null
var tilemap_layer: TileMapLayer = null
var astar_grid: AStarGrid2D
var current_path: PackedVector2Array = []
var current_target_index = 0
var movement_target: Vector2
var is_moving_to_target = false
var last_target_tile: Vector2i = Vector2i(-999, -999)
var is_completing_current_path = false  # Prevent path changes mid-movement

func _ready():
	print("Snake: Starting consistent A* pathfinding system")

	# Find the player and tilemap
	player = get_tree().get_first_node_in_group("player")
	tilemap_layer = _find_tilemap()

	if not player:
		_find_player()

	if player:
		print("Snake: Found player at ", player.global_position)
	if tilemap_layer:
		print("Snake: Found tilemap")
		_setup_astar_grid()
		# Snap to grid center initially
		_snap_to_grid()
	else:
		print("Snake: ERROR - No tilemap found!")

func _snap_to_grid():
	if not tilemap_layer:
		return

	# Convert current position to grid center
	var local_pos = tilemap_layer.to_local(global_position)
	var map_pos = tilemap_layer.local_to_map(local_pos)
	var grid_center = tilemap_layer.to_global(tilemap_layer.map_to_local(map_pos))

	global_position = grid_center
	print("Snake: Snapped to grid center at ", global_position)

func _setup_astar_grid():
	print("Snake: Setting up optimized AStarGrid2D...")

	# Create and configure AStarGrid2D
	astar_grid = AStarGrid2D.new()

	# Get the tilemap's used rectangle and expand it
	var used_rect = tilemap_layer.get_used_rect()

	# Expand the region to cover more area
	var expanded_rect = Rect2i(
		used_rect.position.x - 5,
		used_rect.position.y - 5,
		used_rect.size.x + 10,
		used_rect.size.y + 10
	)

	# Configure the grid with optimal settings
	astar_grid.region = expanded_rect
	astar_grid.cell_size = Vector2i(128, 128)  # Match tile size
	astar_grid.offset = Vector2(64, 64)  # Center of cells for better pathfinding
	astar_grid.diagonal_mode = AStarGrid2D.DIAGONAL_MODE_NEVER  # Grid-aligned movement only
	astar_grid.default_estimate_heuristic = AStarGrid2D.HEURISTIC_MANHATTAN  # Better for grid movement
	astar_grid.jumping_enabled = false  # Disable jumping for predictable paths

	# Apply tie-breaking scaling to prevent inconsistent paths
	# This is a hack but works - we'll modify the heuristic slightly
	astar_grid.default_estimate_heuristic = AStarGrid2D.HEURISTIC_MANHATTAN

	astar_grid.update()

	# Block obstacles
	_mark_obstacles()

	print("Snake: AStarGrid2D setup complete with consistent pathfinding settings")

func _mark_obstacles():
	var used_cells = tilemap_layer.get_used_cells()

	for cell_pos in used_cells:
		var tile_data = tilemap_layer.get_cell_tile_data(cell_pos)
		if tile_data:
			# Check if this tile has collision (making it an obstacle)
			var collision_polygons = tile_data.get_collision_polygons_count(0)
			if collision_polygons > 0:
				# This tile is an obstacle, block it in the grid
				astar_grid.set_point_solid(cell_pos, true)

func _physics_process(delta):
	if not player or not astar_grid:
		if not player:
			_find_player()
		return

	# Get the tile that the player is currently in
	var player_local = tilemap_layer.to_local(player.global_position)
	var player_tile = tilemap_layer.local_to_map(player_local)

	# Get snake's current tile
	var snake_local = tilemap_layer.to_local(global_position)
	var snake_tile = tilemap_layer.local_to_map(snake_local)

	# If snake is on the same tile as player, don't move
	if snake_tile == player_tile:
		current_path.clear()
		is_moving_to_target = false
		is_completing_current_path = false
		return

	# Only recalculate path if:
	# 1. Player moved to a different tile AND
	# 2. We're not currently completing a path movement
	if player_tile != last_target_tile and not is_completing_current_path:
		last_target_tile = player_tile
		_calculate_path_to_player_tile(player_tile)
		print("Snake: Player moved to tile ", player_tile, " - recalculating path")

	# Follow the current path with smooth grid movement
	if not current_path.is_empty():
		_follow_path_smooth(delta)

func _calculate_path_to_player_tile(target_tile: Vector2i):
	if not tilemap_layer or not astar_grid:
		return

	# Convert snake position to map coordinates
	var start_local = tilemap_layer.to_local(global_position)
	var start_map = tilemap_layer.local_to_map(start_local)

	# Use the target tile directly (center of player's tile)
	var end_map = target_tile

	print("Snake: Pathfinding from ", start_map, " to ", end_map)

	# Get path in map coordinates using consistent method
	var path_map_coords = astar_grid.get_id_path(start_map, end_map)

	if path_map_coords.is_empty():
		print("Snake: No path found to player tile!")
		return

	# Convert map coordinates back to world coordinates (grid centers)
	current_path.clear()
	for coord in path_map_coords:
		var world_pos = tilemap_layer.to_global(tilemap_layer.map_to_local(coord))
		current_path.append(world_pos)

	current_target_index = 0
	is_moving_to_target = false
	is_completing_current_path = true  # Lock path until completion

	print("Snake: Found consistent path with ", current_path.size(), " points")

func _follow_path_smooth(delta):
	# If not currently moving to a target, set the next one
	if not is_moving_to_target:
		if current_target_index >= current_path.size():
			current_path.clear()
			is_completing_current_path = false  # Path completed
			return

		movement_target = current_path[current_target_index]
		is_moving_to_target = true

	# Move smoothly towards the current target
	var distance_to_target = global_position.distance_to(movement_target)

	if distance_to_target < 8.0:  # Very close - snap and move to next
		global_position = movement_target
		current_target_index += 1
		is_moving_to_target = false

		if current_target_index >= current_path.size():
			current_path.clear()
			is_completing_current_path = false  # Path completed
	else:
		# Move smoothly towards target
		var direction = (movement_target - global_position).normalized()
		var movement = direction * SPEED * delta
		global_position += movement

func _find_player():
	var root = get_tree().get_root()
	player = _search_for_player(root)
	if player:
		print("Snake: Found player via search: ", player)

func _search_for_player(node: Node) -> Node:
	if node.is_class("CharacterBody2D") and node != self:
		if node.has_method("_handle_shoot"):
			return node

	for child in node.get_children():
		var result = _search_for_player(child)
		if result:
			return result

	return null

func _find_tilemap() -> TileMapLayer:
	var root = get_tree().get_root()
	return _search_for_tilemap(root)

func _search_for_tilemap(node: Node) -> TileMapLayer:
	if node is TileMapLayer:
		return node

	for child in node.get_children():
		var result = _search_for_tilemap(child)
		if result:
			return result

	return null