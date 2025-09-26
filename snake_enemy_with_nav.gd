extends CharacterBody2D

const SPEED = 60.0
const FOLLOW_DISTANCE = 10.0  # Stop this many pixels away from player

var player = null

@onready var nav_agent: NavigationAgent2D = $NavigationAgent2D

func _ready():
	# Find the player in the scene
	player = get_tree().get_first_node_in_group("player")
	if not player:
		print("Snake couldn't find player - will search again")
	else:
		print("Snake found player: ", player)

	# Setup navigation agent
	nav_agent.velocity_computed.connect(_on_velocity_computed)

	# Wait for navigation to be ready
	call_deferred("actor_setup")

func actor_setup():
	# Wait for one physics frame to ensure navigation is ready
	await get_tree().physics_frame
	if player:
		set_movement_target(player.global_position)

func _physics_process(delta):
	if not player:
		# Keep trying to find the player
		_find_player()
		return

	# Update target to player's current position
	set_movement_target(player.global_position)

	# Check if we're close enough to stop
	var distance_to_player = global_position.distance_to(player.global_position)
	if distance_to_player <= FOLLOW_DISTANCE:
		# Stop when close enough
		velocity = Vector2.ZERO
		move_and_slide()
		return

	# Continue with navigation if we're far enough away
	if nav_agent.is_navigation_finished():
		return

	var current_position = global_position
	var next_path_position = nav_agent.get_next_path_position()

	var new_velocity = current_position.direction_to(next_path_position) * SPEED

	# Use navigation agent's avoidance if enabled
	if nav_agent.avoidance_enabled:
		nav_agent.set_velocity(new_velocity)
	else:
		_on_velocity_computed(new_velocity)

	move_and_slide()

func set_movement_target(movement_target: Vector2):
	nav_agent.target_position = movement_target

func _on_velocity_computed(safe_velocity: Vector2):
	velocity = safe_velocity

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