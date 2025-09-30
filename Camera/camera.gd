extends Camera2D

@onready var player: CharacterBody2D = $"../Player"

var follow_speed = 5
var follow_lead = 32
var shake_time: float = 0.0
var shake_frequency: float = 20.0

var shake_intensity: float = 0.0
var shake_duration: float = 0.0

var player_pos: Vector2
var player_ground_pos: Vector2

var target: Vector2

@onready var main_pos: Vector2 = $"../Player".global_position
var shake_offset: Vector2 = Vector2.ZERO

@onready var fog_material = $"../CanvasLayer/ColorRect".material as ShaderMaterial

func _process(delta: float) -> void:
	# MOVE
	player_pos = player.global_position
	if player.is_on_floor():
		player_ground_pos = player_pos + Vector2(0, -32)
	
	target = Vector2(player_pos.x, player_ground_pos.y)
	
	if abs(player_ground_pos.y - player_pos.y) > 64 or player.state == player.state_map[player.PlayerStates.LADDER]:
		target.y = player_pos.y
		player_ground_pos.y = -1000000
	
	if player.state == player.state_map[player.PlayerStates.FREE]:
		target.x += player.input_dir_h * follow_lead
	
	main_pos = main_pos.lerp(target, delta * follow_speed)
	
	# SCREENSHAKE
	if shake_duration > 0:
		shake_duration -= delta
		shake_time += delta
		shake_offset.x = sin(shake_time * shake_frequency) * shake_intensity
		shake_offset.y = cos(shake_time * shake_frequency * 1.2) * shake_intensity * 0.8
		
		shake_intensity = lerp(shake_intensity, 0.0, delta * 5.0)
		
		if shake_duration <= 0:
			shake_offset = Vector2.ZERO
			shake_intensity = 0.0
			shake_time = 0.0
	else:
		shake_offset = Vector2.ZERO
	
	# COMBINE
	global_position = main_pos + shake_offset
	
	# FOG
	fog_material.set_shader_parameter("world_offset", global_position / 640.0)

func start_shake(intensity: float, duration: float):
	shake_intensity = max(intensity, shake_intensity)
	shake_duration = max(duration, shake_duration)
