extends NavigationRegion2D

@onready var tilemap_layer: TileMapLayer = $TileMapLayer

func _ready():
	print("Setting up navigation for tilemap...")

	# Wait for the scene to be fully loaded
	call_deferred("setup_navigation")

func setup_navigation():
	# Create a simple navigation polygon that covers the play area
	# but excludes areas where tiles are placed

	var nav_polygon = NavigationPolygon.new()

	# Define a large rectangle for the navigation area
	# This should cover the entire play area
	var points = PackedVector2Array([
		Vector2(-1000, -1000),  # Top-left
		Vector2(2000, -1000),   # Top-right
		Vector2(2000, 1000),    # Bottom-right
		Vector2(-1000, 1000)    # Bottom-left
	])

	nav_polygon.add_outline(points)

	# Add holes for each tile that has collision
	if tilemap_layer and tilemap_layer.tile_set:
		var used_cells = tilemap_layer.get_used_cells()
		print("Found ", used_cells.size(), " tiles to check for obstacles")

		for cell in used_cells:
			var tile_data = tilemap_layer.get_cell_tile_data(cell)
			if tile_data:
				# Check if this tile has collision (making it an obstacle)
				var collision_polygons = tile_data.get_collision_polygons_count(0)
				if collision_polygons > 0:
					# This tile is an obstacle, create a hole in navigation
					var world_pos = tilemap_layer.to_global(tilemap_layer.map_to_local(cell))
					var tile_size = tilemap_layer.tile_set.tile_size

					# Create a small polygon around the tile as a hole
					var hole_points = PackedVector2Array([
						world_pos + Vector2(-tile_size.x/2, -tile_size.y/2),  # Top-left
						world_pos + Vector2(tile_size.x/2, -tile_size.y/2),   # Top-right
						world_pos + Vector2(tile_size.x/2, tile_size.y/2),    # Bottom-right
						world_pos + Vector2(-tile_size.x/2, tile_size.y/2)    # Bottom-left
					])

					# Convert to local coordinates
					for i in range(hole_points.size()):
						hole_points[i] = to_local(hole_points[i])

					nav_polygon.add_outline(hole_points)
					print("Added obstacle hole at: ", world_pos)

	# Generate the navigation mesh
	nav_polygon.make_polygons_from_outlines()
	navigation_polygon = nav_polygon

	print("Navigation setup complete!")
