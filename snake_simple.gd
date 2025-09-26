extends CharacterBody2D

const SPEED = 60.0
const FOLLOW_DISTANCE = 50.0
const RAYCAST_DISTANCE = 64.0  # How far ahead to check for obstacles

var player = null

func _ready():
	print("Snake: Starting simple movement system")

	# Find the player
	player = get_tree().get_first_node_in_group("player")
	if not player:
		_find_player()

	if player:
		print("Snake: Found player at ", player.global_position)
	else:
		print("Snake: ERROR - No player found!")

func _physics_process(_delta):
	if not player:
		_find_player()
		return

	var distance_to_player = global_position.distance_to(player.global_position)

	# Stop if close enough to player
	if distance_to_player <= FOLLOW_DISTANCE:
		velocity = Vector2.ZERO
		move_and_slide()
		return

	# Calculate direction to player
	var direction_to_player = (player.global_position - global_position).normalized()

	# Check for obstacles in front of us
	var space_state = get_world_2d().direct_space_state

	# Raycast straight ahead
	var query = PhysicsRayQueryParameters2D.create(
		global_position,
		global_position + direction_to_player * RAYCAST_DISTANCE
	)
	query.exclude = [self, player]  # Don't hit ourselves or the player
	query.collision_mask = 1  # Only hit tiles (collision layer 1)

	var result = space_state.intersect_ray(query)

	if result:
		# Hit an obstacle, try to go around it
		print("Snake: Obstacle detected, trying to go around")
		velocity = _get_avoidance_velocity(direction_to_player, result.normal)
	else:
		# Clear path, move directly toward player
		velocity = direction_to_player * SPEED

	move_and_slide()

func _get_avoidance_velocity(desired_direction: Vector2, obstacle_normal: Vector2) -> Vector2:
	# Try moving to the side of the obstacle
	var perpendicular = Vector2(-obstacle_normal.y, obstacle_normal.x)

	# Try both directions and pick the one that gets us closer to the player
	var left_direction = perpendicular
	var right_direction = -perpendicular

	var player_direction = (player.global_position - global_position).normalized()

	# Pick the side that's more aligned with the direction to the player
	var chosen_direction = left_direction
	if right_direction.dot(player_direction) > left_direction.dot(player_direction):
		chosen_direction = right_direction

	return chosen_direction * SPEED

func _find_player():
	# Search through all nodes to find the player
	var root = get_tree().get_root()
	player = _search_for_player(root)

	if player:
		print("Snake: Found player via search: ", player)

func _search_for_player(node: Node) -> Node:
	# Check if this node is the player
	if node.is_class("CharacterBody2D") and node != self:
		if node.has_method("_handle_shoot"):
			return node

	# Search children
	for child in node.get_children():
		var result = _search_for_player(child)
		if result:
			return result

	return null