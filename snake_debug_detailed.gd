extends CharacterBody2D

const SPEED = 60.0
const FOLLOW_DISTANCE = 50.0

var player = null
var tilemap_layer: TileMapLayer = null
var astar_grid: AStarGrid2D
var current_path: PackedVector2Array = []
var current_target_index = 0
var path_recalc_timer = 0.0
var path_recalc_interval = 0.5  # Recalculate path every 0.5 seconds
var debug_frame_count = 0

func _ready():
	print("Snake: Starting AStarGrid2D pathfinding system")

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
	else:
		print("Snake: ERROR - No tilemap found!")

func _setup_astar_grid():
	print("Snake: Setting up AStarGrid2D...")

	# Create and configure AStarGrid2D
	astar_grid = AStarGrid2D.new()

	# Get the tilemap's used rectangle and expand it a bit
	var used_rect = tilemap_layer.get_used_rect()
	print("Snake: Tilemap used rect: ", used_rect)

	# Expand the region to cover more area
	var expanded_rect = Rect2i(
		used_rect.position.x - 5,
		used_rect.position.y - 5,
		used_rect.size.x + 10,
		used_rect.size.y + 10
	)

	# Configure the grid
	astar_grid.region = expanded_rect
	astar_grid.cell_size = Vector2i(128, 128)  # Match tile size
	astar_grid.diagonal_mode = AStarGrid2D.DIAGONAL_MODE_NEVER
	astar_grid.update()

	print("Snake: AStarGrid2D region: ", astar_grid.region)
	print("Snake: AStarGrid2D cell size: ", astar_grid.cell_size)

	# Block obstacles
	_mark_obstacles()

	print("Snake: AStarGrid2D setup complete")

func _mark_obstacles():
	print("Snake: Marking obstacles...")

	var used_cells = tilemap_layer.get_used_cells()
	print("Snake: Found ", used_cells.size(), " tiles to check")

	for cell_pos in used_cells:
		var tile_data = tilemap_layer.get_cell_tile_data(cell_pos)
		if tile_data:
			# Check if this tile has collision (making it an obstacle)
			var collision_polygons = tile_data.get_collision_polygons_count(0)
			if collision_polygons > 0:
				# This tile is an obstacle, block it in the grid
				astar_grid.set_point_solid(cell_pos, true)
				print("Snake: Blocked obstacle at: ", cell_pos)

func _physics_process(delta):
	debug_frame_count += 1

	if not player or not astar_grid:
		if not player:
			_find_player()
		return

	path_recalc_timer += delta

	var distance_to_player = global_position.distance_to(player.global_position)

	# Debug output every 30 frames
	if debug_frame_count % 30 == 0:
		print("=== Snake Debug Frame ", debug_frame_count, " ===")
		print("Snake position: ", global_position)
		print("Player position: ", player.global_position)
		print("Distance to player: ", distance_to_player)
		print("Current velocity: ", velocity)
		print("Path size: ", current_path.size())
		print("Target index: ", current_target_index)
		if not current_path.is_empty():
			print("Path points: ", current_path)
			if current_target_index < current_path.size():
				print("Current target: ", current_path[current_target_index])
				print("Distance to current target: ", global_position.distance_to(current_path[current_target_index]))

	# Stop if close enough to player
	if distance_to_player <= FOLLOW_DISTANCE:
		print("Snake: Close enough to player, stopping")
		velocity = Vector2.ZERO
		current_path.clear()
		move_and_slide()
		return

	# Recalculate path periodically or if we don't have one
	if current_path.is_empty() or path_recalc_timer >= path_recalc_interval:
		path_recalc_timer = 0.0
		_calculate_path_to_player()

	# Follow the current path
	if not current_path.is_empty():
		_follow_path()
	else:
		print("Snake: No path to follow!")

	# Always call move_and_slide
	var old_velocity = velocity
	move_and_slide()

	# Debug movement results
	if debug_frame_count % 30 == 0:
		print("Velocity before move_and_slide: ", old_velocity)
		print("Velocity after move_and_slide: ", velocity)
		print("Position after move_and_slide: ", global_position)

func _calculate_path_to_player():
	if not player or not tilemap_layer or not astar_grid:
		return

	# Convert world positions to map coordinates
	var start_local = tilemap_layer.to_local(global_position)
	var start_map = tilemap_layer.local_to_map(start_local)

	var end_local = tilemap_layer.to_local(player.global_position)
	var end_map = tilemap_layer.local_to_map(end_local)

	print("Snake: Pathfinding from ", start_map, " to ", end_map)

	# Get path in map coordinates
	var path_map_coords = astar_grid.get_id_path(start_map, end_map)

	if path_map_coords.is_empty():
		print("Snake: No path found!")
		return

	# Convert map coordinates back to world coordinates
	current_path.clear()
	for coord in path_map_coords:
		var world_pos = tilemap_layer.to_global(tilemap_layer.map_to_local(coord))
		current_path.append(world_pos)

	current_target_index = 0

	print("Snake: Found path with ", current_path.size(), " points")
	print("Snake: Path in world coordinates: ", current_path)

func _follow_path():
	if current_target_index >= current_path.size():
		print("Snake: Reached end of path, clearing")
		current_path.clear()
		return

	var target = current_path[current_target_index]
	var distance_to_target = global_position.distance_to(target)

	print("Snake: Following path - target index ", current_target_index, " target: ", target, " distance: ", distance_to_target)

	# Move to next waypoint if close enough
	if distance_to_target < 64.0:  # Increased threshold
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
		print("Snake: Setting velocity to ", velocity, " (direction: ", direction, ")")

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
