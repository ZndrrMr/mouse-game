extends CharacterBody2D

# Set collision layer and mask
# Layer 1 = default physics layer (for tilemap collisions)
# We'll be on layer 2 and collide with layer 1

const SPEED = 20.0
const FOLLOW_DISTANCE = 10.0  # Stop this many pixels away from player

var player = null

func _ready():
	# Find the player in the scene
	player = get_tree().get_first_node_in_group("player")
	if not player:
		# Try to find player by node type
		for node in get_tree().get_nodes_in_group(""):
			if node.has_method("_handle_shoot"):  # Player has this method
				player = node
				break

		# If still not found, try by script name
		if not player:
			var nodes = get_tree().get_nodes_in_group("")
			for node in nodes:
				if node.is_class("CharacterBody2D") and node != self:
					if node.get_script() and node.get_script().resource_path.contains("player"):
						player = node
						break

	if player:
		print("Snake found player: ", player)
	else:
		print("Snake couldn't find player - will search again")

func _physics_process(delta):
	if not player:
		# Keep trying to find the player
		_find_player()
		return

	# Calculate direction to player
	var distance_to_player = global_position.distance_to(player.global_position)

	# Only move if we're further than the follow distance
	if distance_to_player > FOLLOW_DISTANCE:
		var direction = (player.global_position - global_position).normalized()
		velocity = direction * SPEED
	else:
		# Stop when close enough
		velocity = Vector2.ZERO

	move_and_slide()

func _find_player():
	# Try to find player dynamically
	var parent = get_parent()
	if parent:
		for child in parent.get_children():
			if child.is_class("CharacterBody2D") and child != self:
				if child.has_method("_handle_shoot"):  # Unique to player
					player = child
					print("Snake found player dynamically: ", player)
					break