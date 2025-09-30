extends CharacterBody2D

@export var segment_count: int = 8
@export var segment_spacing: float = 48.0
var segments: Array[Node2D] = []
var segment_targets: Array[Vector2i] = []

var distance_map : Dictionary = {}
var short_target : Vector2i
var long_target : Vector2i

var sniff_timer : float = 0
var stun_timer : float = 0

const SNIFF_DUR : float = 2
const STUN_DUR : float = 3

var rng = RandomNumberGenerator.new()
@onready var maze: TileMapLayer = $"../TileMapLayer"
var empty_tiles = []

enum SnakeStates {
	CINEMATIC,
	CHASE,
	PATROL,
	KILL,
	STUN,
	SMELL
}
var state_map = {
	SnakeStates.CINEMATIC: Player_State_Free.new().init(self),
	SnakeStates.CHASE: Snake_State_Chase.new().init(self),
	SnakeStates.PATROL: Snake_State_Patrol.new().init(self),
	SnakeStates.KILL: Snake_State_Kill.new().init(self),
	SnakeStates.STUN: Snake_State_Stun.new().init(self),
	SnakeStates.SMELL: Snake_State_Smell.new().init(self)
}
var state: State = null

func _ready() -> void:
	rng.randomize()
	get_empty_tiles()
	set_patrol_target()
	create_segments()
	pick_next_tile()
	
	change_state(SnakeStates.PATROL)
	
	$AudioStreamPlayer2D.play()
	$Heartbeat.play()

func _physics_process(delta: float) -> void:
	if state:
		state.update(delta)
	$AudioStreamPlayer2D.stream_paused = velocity.length() <= 0

func change_state(new_state: SnakeStates) -> void:
	state = state_map[new_state]

func stun_frame(delta: float) -> void:
	stun_timer -= delta
	if stun_timer <= 0:
		change_state(SnakeStates.PATROL)
		set_target(global_to_tile($"../Player".global_position))

func stun() -> void:
	change_state(SnakeStates.STUN)
	stun_timer = STUN_DUR
	$Hiss.play()

func kill_update() -> void:
	var player_pos = global_to_tile($"../Player".global_position)
	if global_to_tile(player_pos) != long_target:
		set_target(player_pos)
	if ($"../Player".is_hidden()):
		change_state(SnakeStates.CHASE)

func sniff(delta:float) -> void:
	var player = $"../Player"
	if !player.is_hidden() && (global_position - player.global_position).length() < 256:
		start_kill()
	sniff_timer -= delta
	if sniff_timer <= 0:
		change_state(SnakeStates.PATROL)
		set_target(global_to_tile($"../Player".global_position))
		$Snort.play()

func start_kill() -> void:
	change_state(SnakeStates.KILL)
	set_target(global_to_tile($"../Player".global_position))
	$Kill.play()

func chase_to_sniff() -> void:
	if short_target == long_target:
		change_state(SnakeStates.SMELL)
		sniff_timer = SNIFF_DUR
		$Sniff.play()

func start_chase() -> void:
	change_state(SnakeStates.CHASE)
	set_target(global_to_tile($"../Player".global_position))

func update_segments(speed: float, delta: float) -> void:
	for i in range(segments.size()):
		move_segment(i, speed, delta)

func create_segments():
	var segment_scene = preload("res://Objects/Snake/segment.tscn")
	
	for i in range(segment_count):
		var segment = segment_scene.instantiate()
		add_child(segment)
		move_child(segment, 0)
		segments.append(segment)
		segment_targets.append(global_to_tile(global_position))
		segment._setup(self)
		
		if (i == segment_count-1):
			segment.get_node("AnimatedSprite2D").animation = "Tail"
		elif (i == segment_count-2):
			segment.get_node("AnimatedSprite2D").animation = "Tail2"
		else:
			segment.get_node("AnimatedSprite2D").animation = "Body"
			
	segment_targets.append(global_to_tile(global_position))

func get_empty_tiles():
	var rect = maze.get_used_rect()
	
	for x in range(rect.size.x):
		for y in range(rect.size.y):
			var tile_pos = Vector2i(x + rect.position.x, y + rect.position.y)
			if maze.get_cell_source_id(tile_pos) == -1:
				empty_tiles.append(tile_pos)
	
	for wall in $"../Walls".get_children():
		empty_tiles.erase(global_to_tile(wall.global_position))

func move_segment(index: int, speed: float, delta: float) -> void:
	var target = segment_targets[index]
	var seg = segments[index]
	
	seg.global_position -= velocity * delta
	
	var distance : Vector2 = tile_to_global(target) - seg.global_position
	var seg_vel = distance.normalized() * speed
	
	if distance.length() < speed * delta:
		seg.global_position = tile_to_global(target)
	else:
		seg.global_position += seg_vel * delta 

func move(speed: float, delta: float) -> void:
	var distance : Vector2 = tile_to_global(short_target) - global_position
	velocity = distance.normalized() * speed
	
	if distance.length() < speed * delta:
		global_position = tile_to_global(short_target)
		
		for i in range(segments.size()):
			segments[i].global_position = tile_to_global(segment_targets[i])
		
		for i in range(segment_targets.size() - 1, 0, -1):
			segment_targets[i] = segment_targets[i-1]
		segment_targets[0] = short_target
		
		if long_target == short_target:
			set_patrol_target()
		else:
			pick_next_tile()
	
	move_and_slide()
	update_segments(speed, delta)

func set_patrol_target() -> void:
	if rng.randf() < 0.6:
		var roll = rng.randi_range(0, empty_tiles.size()-1)
		set_target(empty_tiles[roll])
	else:
		set_target(global_to_tile($"../Player".global_position))

func set_target(target: Vector2):
	long_target = target
	distance_map = flood_fill_towards(target)

func pick_next_tile() -> void:
	var current : Vector2i = global_to_tile(global_position)
	var prev := short_target
	short_target = best_neighbor(current)
	if prev == short_target:
		return
	if short_target == Vector2i.ZERO:
		short_target = prev
		print(state == state_map[SnakeStates.SMELL])
		return
	$AnimatedSprite2D.frame = pick_next_dir(prev, short_target)
	
	for i in range(segment_count):
		segments[i].get_node("AnimatedSprite2D").frame = pick_next_dir(segment_targets[i+1], segment_targets[i])

func best_neighbor(current: Vector2i) -> Vector2i:
	if !distance_map.has(current):
		print("THIS IS WRONG!!")
		print(rng.get_seed())
		return Vector2i.ZERO
	var best_neighbor := current
	var best_dist = distance_map[current]
	
	var neighbors = [
		current + Vector2i.LEFT,
		current + Vector2i.RIGHT,
		current + Vector2i.UP,
		current + Vector2i.DOWN
	]
	
	for n in neighbors:
		if distance_map.has(n) and distance_map[n] < best_dist:
			best_dist = distance_map[n]
			best_neighbor = n
	
	return best_neighbor

func pick_next_dir(prev: Vector2i, current: Vector2i) -> int:
	var delta_tile: Vector2i = current - prev
	
	var returned: int
	if (delta_tile == Vector2i(1, 0)):
		returned = 0
	elif (delta_tile == Vector2i(0, 1)):
		returned = 1
	elif (delta_tile == Vector2i(-1, 0)):
		returned = 2
	elif (delta_tile == Vector2i(0, -1)):
		returned = 3
	else:
		returned = 0
	return returned

func global_to_tile(global: Vector2) -> Vector2i:
	return floor(global / 128)

func tile_to_global(tile: Vector2i) -> Vector2:
	return tile * 128 + Vector2i(64, 64)

func flood_fill_towards(target: Vector2i) -> Dictionary:
	var dist = {}
	var queue = [target]
	dist[target] = 0
	
	if !empty_tiles.has(target):
		empty_tiles.append(target)
		print("added empty tile")
	
	while queue.size() > 0:
		var current = queue.pop_front()
		var neighbors = [
			current + Vector2i.LEFT,
			current + Vector2i.RIGHT,
			current + Vector2i.UP,
			current + Vector2i.DOWN
		]
		for n in neighbors:
			if empty_tiles.has(n) and not dist.has(n): # walkable
				dist[n] = dist[current] + 1
				queue.append(n)
	return dist

func player_caught():
	# Stop all movement/input
	set_physics_process(false)
	$"../Player".set_physics_process(false)

	# Spawn jump scare overlay
	var jump_scare = preload("res://Jumpscare.tscn").instantiate()
	get_tree().current_scene.add_child(jump_scare)
	
	$"../HUD".visible = false

func _on_area_2d_body_entered(body: Node2D) -> void:
	if body.has_method("is_hidden") && !body.is_hidden() && state != state_map[SnakeStates.STUN]:
		player_caught()
	if body.has_method("break_wall"):
		body.break_wall()
