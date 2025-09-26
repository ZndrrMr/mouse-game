extends CharacterBody2D

const SPEED = 60.0
const FOLLOW_DISTANCE = 50.0

var player = null
var use_simple_movement = false

@onready var nav_agent: NavigationAgent2D = $NavigationAgent2D

func _ready():
	print("Snake _ready() called")

	# Find the player in the scene
	player = get_tree().get_first_node_in_group("player")
	if not player:
		print("Snake: Searching for player manually...")
		_find_player()

	if player:
		print("Snake: Found player at position: ", player.global_position)
	else:
		print("Snake ERROR: Could not find player!")

	# Setup navigation agent
	if nav_agent:
		nav_agent.velocity_computed.connect(_on_velocity_computed)
		nav_agent.path_desired_distance = 4.0
		nav_agent.target_desired_distance = 4.0

		# Wait for navigation to be ready
		call_deferred("actor_setup")
	else:
		print("Snake: No NavigationAgent2D found, using simple movement")
		use_simple_movement = true

func actor_setup():
	await get_tree().physics_frame
	await get_tree().physics_frame

	# Test if navigation is working
	if player:
		nav_agent.target_position = player.global_position
		await get_tree().physics_frame

		if nav_agent.is_navigation_finished():
			print("Snake: Navigation not working, falling back to simple movement")
			use_simple_movement = true
		else:
			print("Snake: Navigation system ready")

func _physics_process(_delta):
	if not player:
		_find_player()
		return

	var distance_to_player = global_position.distance_to(player.global_position)

	# Stop if close enough
	if distance_to_player <= FOLLOW_DISTANCE:
		velocity = Vector2.ZERO
		move_and_slide()
		return

	# Choose movement method
	if use_simple_movement:
		_simple_movement()
	else:
		_navigation_movement()

	move_and_slide()

func _simple_movement():
	# Simple direct movement with basic obstacle avoidance
	var direction_to_player = (player.global_position - global_position).normalized()

	# Try direct movement first
	var desired_velocity = direction_to_player * SPEED

	# Test if we can move in that direction (simple collision check)
	var space_state = get_world_2d().direct_space_state
	var query = PhysicsRayQueryParameters2D.create(
		global_position,
		global_position + direction_to_player * 20
	)
	query.exclude = [self]
	var result = space_state.intersect_ray(query)

	if result:
		# Hit an obstacle, try to go around it
		var normal = result.normal
		var slide_direction = direction_to_player.slide(normal).normalized()
		desired_velocity = slide_direction * SPEED
		print("Snake: Obstacle detected, sliding along: ", slide_direction)

	velocity = desired_velocity

func _navigation_movement():
	# Set target and use NavigationAgent2D
	nav_agent.target_position = player.global_position

	if nav_agent.is_navigation_finished():
		velocity = Vector2.ZERO
		return

	var next_path_position = nav_agent.get_next_path_position()
	var direction = (next_path_position - global_position).normalized()
	var desired_velocity = direction * SPEED

	if nav_agent.avoidance_enabled:
		nav_agent.set_velocity(desired_velocity)
	else:
		velocity = desired_velocity

func _on_velocity_computed(safe_velocity: Vector2):
	velocity = safe_velocity

func _find_player():
	var parent = get_parent()
	if parent:
		for child in parent.get_children():
			if child.is_class("CharacterBody2D") and child != self:
				if child.has_method("_handle_shoot"):
					player = child
					print("Snake: Found player: ", player)
					break
