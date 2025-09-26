extends CharacterBody2D

const SPEED = 60.0
const FOLLOW_DISTANCE = 50.0
const TILE_SIZE = 128
const GRID_TOLERANCE = 32  # Increased tolerance

var player = null
var tilemap_layer: TileMapLayer = null
var current_path: Array[Vector2] = []
var current_target_index = 0
var astar = AStar2D.new()
var grid_width = 20
var grid_height = 15
var debug_counter = 0

func _ready():
	print("Snake: Starting A* pathfinding system")

	# Find the player and tilemap
	player = get_tree().get_first_node_in_group("player")
	tilemap_layer = get_node("../NavigationRegion2D/TileMapLayer")

	if not player:
		_find_player()

	if not tilemap_layer:
		print("Snake: Warning - No tilemap found, searching...")
		tilemap_layer = _find_tilemap()

	if player:
		print("Snake: Found player at ", player.global_position)
	if tilemap_layer:
		print("Snake: Found tilemap")
		_setup_astar_grid()
	else:
		print("Snake: ERROR - No tilemap found!")

func _setup_astar_grid():
	print("Snake: Setting up A* grid...")
	astar.clear()

	# Create grid points
	for x in range(grid_width):
		for y in range(grid_height):
			var id = y * grid_width + x
			var world_pos = Vector2(x * TILE_SIZE, y * TILE_SIZE)
			astar.add_point(id, world_pos)

	# Connect adjacent points that are walkable
	for x in range(grid_width):
		for y in range(grid_height):
			var id = y * grid_width + x
			var world_pos = Vector2(x * TILE_SIZE, y * TILE_SIZE)

			# Skip if this position has a tile (obstacle)
			if _is_tile_at_world_position(world_pos):
				continue

			# Connect to adjacent walkable cells
			var neighbors = [
				Vector2(x + 1, y),  # Right
				Vector2(x - 1, y),  # Left
				Vector2(x, y + 1),  # Down
				Vector2(x, y - 1)   # Up
			]

			for neighbor in neighbors:
				if neighbor.x >= 0 and neighbor.x < grid_width and neighbor.y >= 0 and neighbor.y < grid_height:
					var neighbor_id = neighbor.y * grid_width + neighbor.x
					var neighbor_world_pos = Vector2(neighbor.x * TILE_SIZE, neighbor.y * TILE_SIZE)

					# Only connect if neighbor is also walkable
					if not _is_tile_at_world_position(neighbor_world_pos):
						astar.connect_points(id, neighbor_id)

	print("Snake: A* grid setup complete")

func _is_tile_at_world_position(world_pos: Vector2) -> bool:
	if not tilemap_layer:
		return false

	var local_pos = tilemap_layer.to_local(world_pos)
	var map_pos = tilemap_layer.local_to_map(local_pos)
	var tile_data = tilemap_layer.get_cell_tile_data(map_pos)

	# Check if there's a tile with collision
	if tile_data:
		var collision_polygons = tile_data.get_collision_polygons_count(0)
		return collision_polygons > 0

	return false

func _world_to_grid(world_pos: Vector2) -> Vector2:
	return Vector2(
		int(world_pos.x / TILE_SIZE),
		int(world_pos.y / TILE_SIZE)
	)

func _grid_to_id(grid_pos: Vector2) -> int:
	return int(grid_pos.y * grid_width + grid_pos.x)

func _physics_process(_delta):
	debug_counter += 1

	if not player:
		_find_player()
		return

	var distance_to_player = global_position.distance_to(player.global_position)

	# Debug every 30 frames
	if debug_counter % 30 == 0:
		print("Snake Debug:")
		print("  Position: ", global_position)
		print("  Player Position: ", player.global_position)
		print("  Distance to player: ", distance_to_player)
		print("  Current velocity: ", velocity)
		print("  Path size: ", current_path.size())
		print("  Target index: ", current_target_index)
		if not current_path.is_empty() and current_target_index < current_path.size():
			print("  Current target: ", current_path[current_target_index])

	# Stop if close enough to player
	if distance_to_player <= FOLLOW_DISTANCE:
		print("Snake: Close enough to player, stopping")
		velocity = Vector2.ZERO
		current_path.clear()
		move_and_slide()
		return

	# Calculate new path if we don't have one or player moved significantly
	if current_path.is_empty() or _should_recalculate_path():
		print("Snake: Calculating new path...")
		_calculate_path_to_player()

	# Follow the current path
	if not current_path.is_empty():
		_follow_path()
	else:
		print("Snake: No path to follow!")

	move_and_slide()

func _should_recalculate_path() -> bool:
	if current_path.is_empty():
		return true

	# Recalculate every 60 frames to keep path fresh
	return debug_counter % 60 == 0

func _calculate_path_to_player():
	if not player or not tilemap_layer:
		print("Snake: Cannot calculate path - missing player or tilemap")
		return

	var start_grid = _world_to_grid(global_position)
	var end_grid = _world_to_grid(player.global_position)

	print("Snake: Start grid: ", start_grid, " End grid: ", end_grid)

	# Clamp to grid bounds
	start_grid.x = clamp(start_grid.x, 0, grid_width - 1)
	start_grid.y = clamp(start_grid.y, 0, grid_height - 1)
	end_grid.x = clamp(end_grid.x, 0, grid_width - 1)
	end_grid.y = clamp(end_grid.y, 0, grid_height - 1)

	var start_id = _grid_to_id(start_grid)
	var end_id = _grid_to_id(end_grid)

	print("Snake: Start ID: ", start_id, " End ID: ", end_id)

	# Get path from A*
	var path_ids = astar.get_id_path(start_id, end_id)

	print("Snake: Path IDs: ", path_ids)

	# Convert to world positions
	current_path.clear()
	for id in path_ids:
		var world_pos = astar.get_point_position(id)
		current_path.append(world_pos)
		print("Snake: Path point: ", world_pos)

	current_target_index = 0

	if current_path.size() > 1:
		print("Snake: Found path with ", current_path.size(), " points")
	else:
		print("Snake: No valid path found to player")

func _follow_path():
	if current_target_index >= current_path.size():
		print("Snake: Reached end of path")
		current_path.clear()
		return

	var target = current_path[current_target_index]
	var distance_to_target = global_position.distance_to(target)

	print("Snake: Following path - target: ", target, " distance: ", distance_to_target)

	# Move to next waypoint if close enough
	if distance_to_target < GRID_TOLERANCE:
		print("Snake: Reached waypoint ", current_target_index, " moving to next")
		current_target_index += 1
		if current_target_index >= current_path.size():
			print("Snake: Completed path")
			current_path.clear()
			return

	# Move toward current target
	if current_target_index < current_path.size():
		target = current_path[current_target_index]
		var direction = (target - global_position).normalized()
		velocity = direction * SPEED
		print("Snake: Moving toward ", target, " with velocity ", velocity)

func _find_player():
	var root = get_tree().get_root()
	player = _search_for_player(root)

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