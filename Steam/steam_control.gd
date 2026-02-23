extends Node2D

var steam_nodes: Array[GPUParticles2D] = []
var width: int = 7
var height: int = 5
var padding: int = 1

var save_pos : Vector2 = Vector2.ZERO

@onready var tilemap: TileMapLayer = $"../TileMapLayer"

var start : Vector2i = Vector2i(5, 5)
var end : Vector2i = Vector2i(40, 20)

func _ready() -> void:
	var steam_scene = preload("res://Steam/Steam.tscn")
	
	for i in range(start.x, end.x):
		for j in range(start.y, end.y):
			var pos : Vector2 = (128 * Vector2(i, j)) + Vector2(64, 0)
			
			if (is_ground_at_position(pos + Vector2(0, 64)) and
			!is_ground_at_position(pos + Vector2(0, -64))):
				var steam = steam_scene.instantiate()
				add_child(steam)
				steam_nodes.append(steam)
				
				steam.global_position = pos

#func _ready() -> void:
	#var steam_scene = preload("res://Steam/Steam.tscn")
	#
	#for i in range(0, width * height):
		#var steam = steam_scene.instantiate()
		#add_child(steam)
		#steam_nodes.append(steam)
		#
		#var x = i % width
		#var y = i / width
		#
		#steam.global_position = save_pos + (128 * Vector2(x, y)) + Vector2(64, 0)
#
#func _process(delta: float) -> void:
	#var cam = $"../Camera2D"
	#var cam_position_mod = floor((cam.global_position - Vector2(320, 180)) / 128) * 128 - Vector2(128, 128) * padding
	#
	#if save_pos != cam_position_mod:
		#update_steam(cam_position_mod)
#
#func update_steam(cam_position: Vector2):
	#var diff : Vector2 = cam_position - save_pos
	#save_pos = cam_position
	#
	#for i in range(steam_nodes.size()):
		##var x = i % width
		##var y = i / width
		###
		###steam_nodes[i].global_position = cam_position + (128 * Vector2(x, y))
		##if x == 0 or x == width or y == 0 or y == height:
			##print(steam_nodes[i].global_position - cam_position)
			##steam_nodes[i].restart()
		#steam_nodes[i].global_position += diff
		#
		#if (is_ground_at_position(steam_nodes[i].global_position + Vector2(0, 64)) and
		#!is_ground_at_position(steam_nodes[i].global_position + Vector2(0, -64))):
			#steam_nodes[i].emitting = true
		#else:
			#steam_nodes[i].emitting = false

func is_ground_at_position(world_pos: Vector2) -> bool:
	var tile_coords = tilemap.local_to_map(world_pos)
	var tile_data = tilemap.get_cell_tile_data(tile_coords)
	return tile_data != null
