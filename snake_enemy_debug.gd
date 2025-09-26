extends CharacterBody2D

const SPEED = 60.0
const FOLLOW_DISTANCE = 50.0  # Increased to ensure movement happens

var player = null

@onready var nav_agent: NavigationAgent2D = $NavigationAgent2D

func _ready():
	print("Snake _ready() called")

	# Find the player in the scene
	player = get_tree().get_first_node_in_group("player")
	if not player:
		print("Snake ERROR: couldn't find player in 'player' group")
		_find_player()
	else:
		print("Snake SUCCESS: found player: ", player, " at position: ", player.global_position)

	# Setup navigation agent
	if nav_agent:
		print("Snake: NavigationAgent2D found")
		nav_agent.velocity_computed.connect(_on_velocity_computed)

		# Set some navigation agent properties
		nav_agent.path_desired_distance = 4.0
		nav_agent.target_desired_distance = 4.0
		nav_agent.path_max_distance = 10.0
	else:
		print("Snake ERROR: NavigationAgent2D not found!")

	# Wait for navigation to be ready
	call_deferred("actor_setup")

func actor_setup():
	print("Snake actor_setup() called")
	# Wait for multiple physics frames to ensure navigation is ready
	await get_tree().physics_frame
	await get_tree().physics_frame

	if player:
		print("Snake: Setting initial target to player position: ", player.global_position)
		set_movement_target(player.global_position)
	else:
		print("Snake ERROR: No player found in actor_setup")

func _physics_process(delta):
	if not player:
		# Keep trying to find the player
		_find_player()
		return

	# Debug: Print positions every 60 frames (roughly once per second)
	if Engine.get_process_frames() % 60 == 0:
		print("Snake position: ", global_position, " Player position: ", player.global_position)
		print("Distance to player: ", global_position.distance_to(player.global_position))
		print("Navigation finished: ", nav_agent.is_navigation_finished())
		print("Target position: ", nav_agent.target_position)

	# Update target to player's current position
	set_movement_target(player.global_position)

	# Check if we're close enough to stop
	var distance_to_player = global_position.distance_to(player.global_position)
	if distance_to_player <= FOLLOW_DISTANCE:
		print("Snake: Close enough to player, stopping")
		velocity = Vector2.ZERO
		move_and_slide()
		return

	# Continue with navigation if we're far enough away
	if nav_agent.is_navigation_finished():
		print("Snake: Navigation finished, no path")
		return

	var current_position = global_position
	var next_path_position = nav_agent.get_next_path_position()

	print("Snake: Next path position: ", next_path_position)

	var new_velocity = current_position.direction_to(next_path_position) * SPEED
	print("Snake: Calculated velocity: ", new_velocity)

	# Use navigation agent's avoidance if enabled
	if nav_agent.avoidance_enabled:
		nav_agent.set_velocity(new_velocity)
	else:
		_on_velocity_computed(new_velocity)

	move_and_slide()
	print("Snake: After move_and_slide, velocity: ", velocity)

func set_movement_target(movement_target: Vector2):
	if nav_agent:
		nav_agent.target_position = movement_target
		print("Snake: Target set to: ", movement_target)

func _on_velocity_computed(safe_velocity: Vector2):
	velocity = safe_velocity
	print("Snake: Velocity computed: ", safe_velocity)

func _find_player():
	print("Snake: Searching for player...")
	# Try to find player dynamically
	var parent = get_parent()
	if parent:
		for child in parent.get_children():
			print("Snake: Checking child: ", child, " type: ", child.get_class())
			if child.is_class("CharacterBody2D") and child != self:
				if child.has_method("_handle_shoot"):  # Unique to player
					player = child
					print("Snake SUCCESS: Found player dynamically: ", player)
					break