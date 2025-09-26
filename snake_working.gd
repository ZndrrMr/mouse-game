extends CharacterBody2D

const SPEED = 60.0
const FOLLOW_DISTANCE = 50.0

var player = null

func _ready():
	print("Snake: Simple working movement starting")

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

	# Debug every 60 frames
	if Engine.get_process_frames() % 60 == 0:
		print("Snake: Position ", global_position, " Player ", player.global_position, " Distance ", distance_to_player)

	# Stop if close enough to player
	if distance_to_player <= FOLLOW_DISTANCE:
		velocity = Vector2.ZERO
		move_and_slide()
		return

	# Simple movement toward player with wall sliding
	var direction_to_player = (player.global_position - global_position).normalized()
	velocity = direction_to_player * SPEED

	# This will automatically slide along walls due to move_and_slide()
	move_and_slide()

	# Debug velocity after movement
	if Engine.get_process_frames() % 60 == 0:
		print("Snake: Velocity set to ", velocity)

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